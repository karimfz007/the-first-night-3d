import { writeFile } from "node:fs/promises";

await writeFile(new URL("../../node_modules/.gdignore", import.meta.url), "");
