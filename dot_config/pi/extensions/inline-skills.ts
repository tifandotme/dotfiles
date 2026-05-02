// @ts-nocheck
import { readFileSync } from "node:fs";
import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";

type AutocompleteItem = {
	value: string;
	label: string;
	description?: string;
};

type AutocompleteSuggestions = {
	items: AutocompleteItem[];
	prefix: string;
};

type AutocompleteProvider = {
	getSuggestions(
		lines: string[],
		cursorLine: number,
		cursorCol: number,
		options: { signal: AbortSignal; force?: boolean },
	): Promise<AutocompleteSuggestions | null>;
	applyCompletion(
		lines: string[],
		cursorLine: number,
		cursorCol: number,
		item: AutocompleteItem,
		prefix: string,
	): { lines: string[]; cursorLine: number; cursorCol: number };
	shouldTriggerFileCompletion?(
		lines: string[],
		cursorLine: number,
		cursorCol: number,
	): boolean;
};

type SkillCommand = {
	name: string;
	description?: string;
	source: string;
	sourceInfo: {
		path: string;
	};
};

type SkillInfo = {
	name: string;
	description?: string;
	filePath: string;
	baseDir: string;
};

const MAX_SUGGESTIONS = 30;
const SKILL_TOKEN_RE = /(^|[\s([{,])\$([a-z0-9][a-z0-9-]{0,63})/gi;
const DOLLAR_SKILL_CONTEXT_RE = /(?:^|[\s([{,])\$[a-z0-9-]*$/i;

function stripFrontmatter(content: string): string {
	if (!content.startsWith("---")) return content;
	const end = content.indexOf("\n---", 3);
	if (end === -1) return content;
	const after = content.indexOf("\n", end + 4);
	return after === -1 ? "" : content.slice(after + 1);
}

function skillDirFromFilePath(filePath: string): string {
	return filePath.replace(/\/SKILL\.md$/i, "").replace(/\/[^/]+\.md$/i, "");
}

function fuzzyScore(value: string, query: string): number {
	const target = value.toLowerCase();
	const needle = query.toLowerCase();
	if (!needle) return 1;
	if (target === needle) return 1000;
	if (target.startsWith(needle)) return 800 - target.length;
	if (target.includes(needle))
		return 600 - target.indexOf(needle) - target.length;

	let score = 0;
	let lastIndex = -1;
	for (const char of needle) {
		const index = target.indexOf(char, lastIndex + 1);
		if (index === -1) return 0;
		score += index === lastIndex + 1 ? 20 : 5;
		lastIndex = index;
	}
	return score - target.length;
}

function filterSkills(skills: SkillInfo[], query: string): SkillInfo[] {
	return skills
		.map((skill) => ({ skill, score: fuzzyScore(skill.name, query) }))
		.filter((entry) => entry.score > 0)
		.sort(
			(a, b) => b.score - a.score || a.skill.name.localeCompare(b.skill.name),
		)
		.map((entry) => entry.skill);
}

function getSkills(pi: ExtensionAPI): SkillInfo[] {
	return (pi.getCommands() as SkillCommand[])
		.filter(
			(command) =>
				command.source === "skill" && command.name.startsWith("skill:"),
		)
		.map((command) => {
			const filePath = command.sourceInfo.path;
			return {
				name: command.name.slice("skill:".length),
				description: command.description,
				filePath,
				baseDir: skillDirFromFilePath(filePath),
			};
		});
}

function buildSkillBlock(skill: SkillInfo): string {
	const content = readFileSync(skill.filePath, "utf-8");
	const body = stripFrontmatter(content).trim();
	return `<skill name="${skill.name}" location="${skill.filePath}">\nReferences are relative to ${skill.baseDir}.\n\n${body}\n</skill>`;
}

function buildMultiSkillBlock(skills: SkillInfo[]): string {
	const names = skills.map((skill) => skill.name).join(", ");
	const locations = skills.map((skill) => skill.filePath).join(", ");
	const sections = skills
		.map((skill) => {
			const content = readFileSync(skill.filePath, "utf-8");
			const body = stripFrontmatter(content).trim();
			return `## ${skill.name}\nLocation: ${skill.filePath}\nReferences are relative to ${skill.baseDir}.\n\n${body}`;
		})
		.join("\n\n---\n\n");

	return `<skill name="${names}" location="${locations}">\n${sections}\n</skill>`;
}

function expandInlineSkills(
	text: string,
	skills: SkillInfo[],
): string | undefined {
	const byName = new Map(skills.map((skill) => [skill.name, skill]));
	const selected: SkillInfo[] = [];
	const seen = new Set<string>();

	let rewritten = text.replace(
		SKILL_TOKEN_RE,
		(match, boundary: string, skillName: string) => {
			const skill = byName.get(skillName);
			if (!skill) return match;
			if (!seen.has(skill.name)) {
				seen.add(skill.name);
				selected.push(skill);
			}
			return `${boundary}\`${skill.name}\``;
		},
	);

	if (selected.length === 0) return undefined;

	rewritten = rewritten.replace(/[ \t]{2,}/g, " ").trim();
	const blocks =
		selected.length === 1
			? buildSkillBlock(selected[0])
			: buildMultiSkillBlock(selected);
	return rewritten ? `${blocks}\n\nUser: ${rewritten}` : blocks;
}

function extractDollarSkillPrefix(
	textBeforeCursor: string,
): string | undefined {
	const match = textBeforeCursor.match(/(?:^|[\s([{,])\$([a-z0-9-]*)$/i);
	return match?.[1];
}

function installDollarAutocompleteTrigger(): void {
	const proto = CustomEditor.prototype as unknown as {
		handleInput(data: string): void;
		__inlineSkillsDollarTriggerInstalled?: boolean;
	};
	if (proto.__inlineSkillsDollarTriggerInstalled) return;

	const originalHandleInput = proto.handleInput;
	proto.handleInput = function patchedHandleInput(
		this: unknown,
		data: string,
	): void {
		originalHandleInput.call(this, data);

		const editor = this as {
			isShowingAutocomplete?: () => boolean;
			getText?: () => string;
			state?: { cursorLine: number; cursorCol: number; lines: string[] };
			tryTriggerAutocomplete?: () => void;
		};
		if (
			editor.isShowingAutocomplete?.() ||
			!editor.state ||
			typeof editor.tryTriggerAutocomplete !== "function"
		)
			return;
		if (!/^[a-zA-Z0-9\-_$]$/.test(data)) return;

		const currentLine = editor.state.lines[editor.state.cursorLine] ?? "";
		const textBeforeCursor = currentLine.slice(0, editor.state.cursorCol);
		if (DOLLAR_SKILL_CONTEXT_RE.test(textBeforeCursor)) {
			editor.tryTriggerAutocomplete();
		}
	};
	proto.__inlineSkillsDollarTriggerInstalled = true;
}

function createDollarSkillAutocompleteProvider(
	pi: ExtensionAPI,
	current: AutocompleteProvider,
): AutocompleteProvider {
	return {
		async getSuggestions(
			lines,
			cursorLine,
			cursorCol,
			options,
		): Promise<AutocompleteSuggestions | null> {
			const currentLine = lines[cursorLine] ?? "";
			const textBeforeCursor = currentLine.slice(0, cursorCol);
			const query = extractDollarSkillPrefix(textBeforeCursor);
			if (query === undefined) {
				return current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			const skills = getSkills(pi);
			if (options.signal.aborted || skills.length === 0) {
				return current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			const matches = query
				? filterSkills(skills, query).slice(0, MAX_SUGGESTIONS)
				: skills.slice(0, MAX_SUGGESTIONS);

			if (matches.length === 0) {
				return current.getSuggestions(lines, cursorLine, cursorCol, options);
			}

			return {
				prefix: `$${query}`,
				items: matches.map(
					(skill): AutocompleteItem => ({
						value: `$${skill.name}`,
						label: skill.name,
						description: skill.description,
					}),
				),
			};
		},

		applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
			if (!prefix.startsWith("$")) {
				return current.applyCompletion(
					lines,
					cursorLine,
					cursorCol,
					item,
					prefix,
				);
			}

			const currentLine = lines[cursorLine] ?? "";
			const beforePrefix = currentLine.slice(0, cursorCol - prefix.length);
			const afterCursor = currentLine.slice(cursorCol);
			const suffix = afterCursor.startsWith(" ") ? "" : " ";
			const nextLines = [...lines];
			nextLines[cursorLine] =
				`${beforePrefix}${item.value}${suffix}${afterCursor}`;
			return {
				lines: nextLines,
				cursorLine,
				cursorCol: beforePrefix.length + item.value.length + suffix.length,
			};
		},

		shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
			return (
				current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ??
				true
			);
		},
	};
}

export default function (pi: ExtensionAPI): void {
	installDollarAutocompleteTrigger();

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.addAutocompleteProvider((current) =>
			createDollarSkillAutocompleteProvider(pi, current),
		);
	});

	pi.on("input", async (event, ctx) => {
		if (event.source === "extension" || !event.text.includes("$")) {
			return { action: "continue" };
		}

		try {
			const expanded = expandInlineSkills(event.text, getSkills(pi));
			if (!expanded) return { action: "continue" };
			return { action: "transform", text: expanded, images: event.images };
		} catch (error) {
			ctx.ui.notify(
				`inline-skills: failed to expand skill: ${error instanceof Error ? error.message : String(error)}`,
				"error",
			);
			return { action: "continue" };
		}
	});
}
