export function validateLearningStartBlock(startBlock, blockCount) {
  if (!Number.isSafeInteger(blockCount) || blockCount < 1) {
    throw new Error("Part I must contain at least one learning block.");
  }
  if (!Number.isSafeInteger(startBlock) || startBlock < 1 || startBlock > blockCount) {
    throw new Error(`Starting block must be an integer between 1 and ${blockCount}.`);
  }
}

// Count before slicing: resuming must not relabel blocks or change stimulus sets.
export function createLearningBlockPlan(orderedLayouts, startBlock = 1) {
  validateLearningStartBlock(startBlock, orderedLayouts?.length);
  const localBlockCounters = new Map();
  return orderedLayouts.map((layoutType, index) => {
    const localBlockIndex = (localBlockCounters.get(layoutType) ?? 0) + 1;
    localBlockCounters.set(layoutType, localBlockIndex);
    return {
      layoutType,
      localBlockIndex,
      globalBlockIndex: index + 1,
      block: `${layoutType}_${localBlockIndex}`,
    };
  }).slice(startBlock - 1);
}
