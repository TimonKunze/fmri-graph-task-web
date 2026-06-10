import { spawnSync } from "node:child_process";
import { mkdirSync } from "node:fs";

const deploymentDate = new Date().toISOString();
const deploymentComment = process.argv.slice(2).join(" ").trim();
const basePrefix = process.env.DEPLOY_BASE_PREFIX || "/";
const saveDataUrl = process.env.DEPLOY_SAVE_DATA_URL || "/fmri_exp/exp_data/save_data.php";
const experimentFolder =
  process.env.DEPLOY_EXPERIMENT_FOLDER ||
  basePrefix.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean).at(-1) ||
  "experiment";
const experimentVersion =
  process.env.VITE_EXPERIMENT_VERSION ||
  process.env.DEPLOY_EXPERIMENT_VERSION ||
  experimentFolder;

function normalizeBasePath(prefix, part) {
  const trimmed = prefix.replace(/^\/+|\/+$/g, "");
  return trimmed ? `/${trimmed}/part${part}/` : `/part${part}/`;
}

const builds = [
  { part: "1", outDir: "dist/part1" },
  { part: "2", outDir: "dist/part2" },
  { part: "3", outDir: "dist/part3" },
].map((build) => ({
  ...build,
  base: normalizeBasePath(basePrefix, build.part),
}));

mkdirSync("dist", { recursive: true });

for (const build of builds) {
  const result = spawnSync(
    "npx",
    ["vite", "build", "--outDir", build.outDir],
    {
      stdio: "inherit",
      env: {
        ...process.env,
        VITE_ACTIVE_PART: build.part,
        VITE_BASE_PATH: build.base,
        VITE_SAVE_DATA_URL: saveDataUrl,
        VITE_EXPERIMENT_FOLDER: experimentFolder,
        VITE_EXPERIMENT_VERSION: experimentVersion,
        VITE_DEPLOYMENT_DATE: deploymentDate,
        VITE_DEPLOYMENT_COMMENT: deploymentComment,
      },
    }
  );

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log("Finished building experiment parts:", builds);
