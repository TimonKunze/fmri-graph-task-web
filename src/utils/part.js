import { PATHS } from "../config/paths.js";

export function parseActivePart(value, fallback) {
  if (value === undefined || value === null || String(value).trim() === "") {
    return fallback;
  }

  const normalized = String(value).trim().toLowerCase();
  const allowedParts = new Set(["1", "2a", "2b", "3"]);

  if (allowedParts.has(normalized)) {
    return normalized;
  }

  const numericValue = Number(normalized);
  if (Number.isInteger(numericValue)) {
    const numericPart = String(numericValue);
    if (allowedParts.has(numericPart)) {
      return numericPart;
    }
  }

  throw new Error(`CONFIG.activePart must be 1, 2a, 2b, or 3. Received: ${value}`);
}

export function getPart2LearningStimulusOrder() {
  return [2, 0, 1];
}

export function getPart2LearningStimulusPaths() {
  return getPart2LearningStimulusOrder().map((nodeIndex) => PATHS.nodeExport(nodeIndex + 1));
}
