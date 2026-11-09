import { execFileSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Sites has a 32 MiB per-object source limit. Keep the GitHub history intact;
// publish a reproducible source snapshot containing the demo's build inputs.
const root = fileURLToPath(new URL("../", import.meta.url));
const git = (...args) => execFileSync("git", args, { cwd: root, encoding: "utf8" }).trim();
if (git("status", "--porcelain")) throw new Error("Commit source changes before preparing a hosting snapshot.");
if (!process.argv[2]) throw new Error("Pass an empty destination directory.");
const destination = resolve(process.argv[2]);
if (destination === root || (existsSync(destination) && readdirSync(destination).length)) {
  throw new Error("The hosting snapshot destination must be empty.");
}
mkdirSync(destination, { recursive: true });
const assets = ["brand/", "demo/", "fonts/", "default-profile.png"];
const files = git("ls-files", "-z").split("\0").filter(Boolean);
for (const file of files) {
  const isFrontend = file.startsWith("frontend/") &&
    (!file.startsWith("frontend/public/") || assets.some(asset => file.startsWith(`frontend/public/${asset}`)));
  if (!isFrontend && ![".gitignore", ".openai/hosting.json", "package.json", "scripts/prepare-demo-hosting.mjs"].includes(file)) continue;
  mkdirSync(dirname(join(destination, file)), { recursive: true });
  cpSync(join(root, file), join(destination, file));
}
writeFileSync(join(destination, "SOURCE_REVISION.json"), JSON.stringify({
  repository: "https://github.com/jeffreymutethia/Seattle-Pulse",
  commit: git("rev-parse", "HEAD"),
  scope: "Unmodified demo build inputs; unrelated backend/mobile source and full-app media omitted.",
}, null, 2) + "\n");
console.log(destination);
