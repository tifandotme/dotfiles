import {
  CustomEditor,
  FooterComponent,
  type AgentSession,
  type ExtensionAPI,
  type ExtensionContext,
  type KeybindingsManager,
  type ReadonlyFooterDataProvider,
  type Theme,
} from "@earendil-works/pi-coding-agent"
import type { EditorTheme, TUI } from "@earendil-works/pi-tui"

function isUsingSubscription(
  ctx: ExtensionContext,
  providerId: string,
): boolean {
  const model = ctx.model
  if (!model || model.provider !== providerId) return false

  const provider = ctx.modelRegistry.getProvider(providerId)
  return (
    ctx.modelRegistry.isUsingOAuth(model) &&
    provider?.auth.oauth?.isSubscription === true
  )
}

class MinimalFooter extends FooterComponent {
  private readonly unsubscribe: () => void

  constructor(
    ctx: ExtensionContext,
    tui: TUI,
    footerData: ReadonlyFooterDataProvider,
  ) {
    const session = {
      get state() {
        return { model: ctx.model, thinkingLevel: ctx.thinkingLevel }
      },
      sessionManager: ctx.sessionManager,
      modelRuntime: {
        isUsingSubscription: (providerId: string) =>
          isUsingSubscription(ctx, providerId),
      },
      getContextUsage: () => ctx.getContextUsage(),
    }
    const hiddenFooterData: ReadonlyFooterDataProvider = {
      getGitBranch: () => footerData.getGitBranch(),
      getExtensionStatuses: () => new Map<string, string>(),
      getAvailableProviderCount: () => footerData.getAvailableProviderCount(),
      onBranchChange: (callback) => footerData.onBranchChange(callback),
    }

    super(session as unknown as AgentSession, hiddenFooterData)
    this.setAutoCompactEnabled(false)
    this.unsubscribe = footerData.onBranchChange(() => tui.requestRender())
  }

  override dispose(): void {
    this.unsubscribe()
    super.dispose()
  }
}

class FixedThinkingEditor extends CustomEditor {
  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    private readonly ctx: ExtensionContext,
  ) {
    super(tui, theme, keybindings)
  }

  override render(width: number): string[] {
    const isBashMode = this.getText().trimStart().startsWith("!")
    this.borderColor = isBashMode
      ? this.ctx.ui.theme.getBashModeBorderColor()
      : this.ctx.ui.theme.getThinkingBorderColor("minimal")
    return super.render(width)
  }
}

export default function (pi: ExtensionAPI): void {
  let showExtensionStatus = false

  pi.registerCommand("toggle-extension-status", {
    description: "show or hide the extension status row",
    handler: async (_args, ctx) => {
      if (ctx.mode !== "tui") return

      showExtensionStatus = !showExtensionStatus
      ctx.ui.setFooter(showExtensionStatus ? undefined : createFooter(ctx))
    },
  })

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return

    showExtensionStatus = false
    ctx.ui.setFooter(createFooter(ctx))
    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) =>
        new FixedThinkingEditor(tui, theme, keybindings, ctx),
    )
  })
}

function createFooter(ctx: ExtensionContext) {
  return (tui: TUI, _theme: Theme, footerData: ReadonlyFooterDataProvider) =>
    new MinimalFooter(ctx, tui, footerData)
}
