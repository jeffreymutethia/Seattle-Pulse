import { cpSync, lstatSync, mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

// Export only assets used by the walkthrough, keeping full-app media out of it.
const source = new URL("../public/", import.meta.url);
const destination = fileURLToPath(new URL("../demo/public", import.meta.url));
if (lstatSync(destination, { throwIfNoEntry: false })?.isSymbolicLink()) {
  throw new Error("The generated demo/public directory must not be a symlink.");
}
rmSync(destination, { recursive: true, force: true });
mkdirSync(destination, { recursive: true });
for (const asset of ["brand", "demo", "fonts", "default-profile.png", "bg-up.png", "Feed.svg", "Pulse.svg", "Forward.png"]) {
  cpSync(new URL(asset, source), join(destination, asset), { recursive: true });
}
cpSync(new URL("../app/favicon.ico", import.meta.url), join(destination, "favicon.ico"));
