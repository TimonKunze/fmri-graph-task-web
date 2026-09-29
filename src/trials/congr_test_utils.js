export function getCongrChoiceOrder(choices, shouldRandomize, randomValue = Math.random()) {
  const choiceSwitched = shouldRandomize && randomValue < 0.5;
  return {
    choices: choiceSwitched ? [...choices].reverse() : [...choices],
    choiceSwitched,
  };
}
