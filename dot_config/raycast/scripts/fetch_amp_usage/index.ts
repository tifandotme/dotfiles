// Fetches Amp usage status by running `amp usage` command
// Outputs: "free_remaining/total actual_credits" (e.g., "0.75/10 91.81")

const ampPath = `${process.env.HOME}/.local/share/bun/bin/amp`;
const result = await Bun.$`${ampPath} usage`.nothrow();
const output = result.stdout.toString();

// Parse free tier: "$0.75/$10 remaining"
const freeMatch = output.match(/\$(\d+\.?\d*)\/\$(\d+)/);
// Parse individual credits: "$91.81 remaining"
const creditsMatch = output.match(/Individual credits: \$(\d+\.?\d*)/);

if (freeMatch && creditsMatch) {
  const freeRemaining = freeMatch[1];
  const freeTotal = freeMatch[2];
  const actualCredits = creditsMatch[1];
  console.log(`${freeRemaining}/${freeTotal} ${actualCredits}`);
} else {
  console.error("Could not parse amp usage output");
  process.exit(1);
}
