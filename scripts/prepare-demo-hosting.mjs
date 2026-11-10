import { cpSync, existsSync, mkdirSync, rmSync } from "node:fs";

// Sites serves the exact static Next.js export tested by the demo browser job.
const source = new URL("../frontend/demo/out/", import.meta.url);
const destination = new URL("../out/", import.meta.url);
if (!existsSync(new URL("index.html", source))) {
  throw new Error("Build the demo first: npm --prefix frontend run build:demo");
}
rmSync(destination, { recursive: true, force: true });
mkdirSync(destination, { recursive: true });
cpSync(source, destination, { recursive: true });
