import { register } from "node:module";

// Keep the actual setup/timeline logic, but replace browser rendering and the
// automatic main.js bootstrap so these regressions also run in plain Node.
export function registerPart1ModuleMocks() {
  const root = new URL("../../src/", import.meta.url);
  const mocks = {
    "@jspsych/plugin-html-button-response": "export default class HtmlButtonResponse {}",
  };
  const mock = (path, source) => { mocks[new URL(path, root).href] = source; };
  mock("main.js", "export const jsPsych = globalThis.__part1TestJsPsych;");
  mock("build/derivedDesign.js", 'export const DESIGN = {rotationPos: "rotational positions", randomPoss: "random positions"};');
  mock("config/sample_graph.js", "export const G_SAMPLE = {nodepos: [], relations: [[0, 1]]};");
  mock("timelines/learn_timelines.js", `
    export const createLearnTrials = (positions, block) => [{data: {trial_name: "learning", block}, positions}];
    export const createRelQueryTrials = (passes, block) => [{data: {trial_name: "relation_query", block}}];
  `);
  for (const part of ["2a", "2b", "3"]) {
    mock(`timelines/part${part}_timeline.js`, `export const makePart${part}Timeline = () => [{data: {trial_name: "part${part}"}}];`);
  }
  const trials = {
    gender_trial: "gender_trial",
    learn_instr_end_trial: "learnInstrEndTrial",
    learn_instr_trial: "learnInstrTrial",
    learn_set_transition_trial: "learnSetTransitionTrial",
    age_trial: "age_trial",
    preload_trial: "preload_trial",
    welcome_trial: "welcome_trial",
    consent_trial: "consent_trial",
    learn_rel_query_instr_trial: "learnTrialRelQueryInstr",
    final_part1_trial: "finalPart1Trial",
  };
  for (const [file, name] of Object.entries(trials)) {
    mock(`trials/${file}.js`, `export const ${name} = {data: {trial_name: "${file}"}};`);
  }
  for (const name of ["createLearnTrialAnim", "createDrawingTrial", "createDrawingTrialSummary"]) {
    mock(`trials/${name}.js`, `export const ${name} = () => ({data: {trial_name: "practice"}});`);
  }
  mock("trials/rel_query_feedback_trial.js", 'export const createRelQueryTrialFeedback = () => ({data: {trial_name: "feedback"}});');
  mock("trials/eval_trials.js", `
    export const createConfidenceTrial = () => ({data: {trial_name: "confidence"}});
    export const createFreeEvalTrial = () => ({data: {trial_name: "evaluation"}});
  `);

  const loader = `
    let mocks;
    export function initialize(data) { mocks = data; }
    export async function resolve(specifier, context, nextResolve) {
      const key = Object.hasOwn(mocks, specifier) ? specifier :
        (context.parentURL?.startsWith("file:") ? new URL(specifier, context.parentURL).href : specifier);
      if (Object.hasOwn(mocks, key)) {
        return {url: "data:text/javascript," + encodeURIComponent(mocks[key]), shortCircuit: true};
      }
      return nextResolve(specifier, context);
    }
  `;
  register(`data:text/javascript,${encodeURIComponent(loader)}`, { data: mocks });
}
