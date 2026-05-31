// src/utils/graph-tools.js

export function createMatrix(m, n, fillVal) {
  const result = [];
  for (let i = 0; i < n; i++) result.push(new Array(m).fill(fillVal));
  return result;
}

export function arraysEqual(a1, a2) {
  return JSON.stringify(a1) === JSON.stringify(a2);
}

export function getListOfUniqueEntries(lst) {
  const lstUnique = [];
  for (const entry of lst) {
    let isUnique = true;
    for (const uniqueEntry of lstUnique) {
      if (arraysEqual(entry, uniqueEntry)) {
        isUnique = false;
        break;
      }
    }
    if (isUnique) lstUnique.push(entry);
  }
  return lstUnique;
}

export function sortPathPairsByLen(pathPairs) {
  return pathPairs.map(pair => pair.sort((a, b) => a.length - b.length));
}


/* Randomly reverses the inner and outer lists in a two-
 * times nested list. Has no return value but modifies 
 * the list directly.
 */
export function randomlyReverseLists(nestedList) {
  for (let i=0; i<nestedList.length; i++) {
    let randomBinary2 = Math.floor(Math.random()*2);
    if (randomBinary2) {
      nestedList[i][0].reverse();
    }

    let randomBinary3 = Math.floor(Math.random()*2);
    if (randomBinary3) {
      nestedList[i][1].reverse();
    }
    let randomBinary1 = Math.floor(Math.random()*2);
    if (randomBinary1) {
      nestedList[i].reverse();
    }
  }
}


export function sortPathPairsByNb(pathPairs) {
  const pathPairsNbSort = [];
  for (const pathPair of pathPairs) {
    const pathPairRev = [];
    for (const p of pathPair) {
      if (p[0] > p[p.length - 1]) {
        pathPairRev.push([...p].reverse()); // avoid mutating original
      } else {
        pathPairRev.push(p);
      }
    }
    pathPairsNbSort.push(pathPairRev);
  }
  return pathPairsNbSort;
}

export function sortPathPairs(pathPairs) {
  const pathPairsLenSort = sortPathPairsByLen(pathPairs);
  return sortPathPairsByNb(pathPairsLenSort);
}

export function transformToAdjacencyObject(nbNodes, adjList) {
  const adjacencyObject = {};
  for (let i = 0; i < nbNodes; i++) adjacencyObject[i] = [];
  for (const [node1, node2] of adjList) {
    adjacencyObject[node1].push(node2);
    adjacencyObject[node2].push(node1);
  }
  return adjacencyObject;
}

export function isConnected(graph) {
  const visited = new Set();
  const nodes = Object.keys(graph);
  if (nodes.length === 0) return true;

  const startNode = Number(nodes[0]);

  function dfs(node) {
    if (visited.has(node)) return;
    visited.add(node);
    for (const neighbor of graph[node]) dfs(neighbor);
  }

  dfs(startNode);
  return visited.size === nodes.length;
}

export function createShortestPathDistanceMatrix(adjM) {
  if (!Array.isArray(adjM)) return [];

  const nbNodes = adjM.length;
  const distanceMatrix = Array.from(
    { length: nbNodes },
    () => new Array(nbNodes).fill(null)
  );

  for (let startNode = 0; startNode < nbNodes; startNode++) {
    const queue = [[startNode, 0]];
    const visited = new Set([startNode]);
    distanceMatrix[startNode][startNode] = 0;

    while (queue.length > 0) {
      const [node, distance] = queue.shift();

      for (let nextNode = 0; nextNode < nbNodes; nextNode++) {
        const isNeighbor = adjM[node]?.[nextNode] === 1 || adjM[nextNode]?.[node] === 1;
        if (!isNeighbor || visited.has(nextNode)) continue;

        visited.add(nextNode);
        distanceMatrix[startNode][nextNode] = distance + 1;
        queue.push([nextNode, distance + 1]);
      }
    }
  }

  return distanceMatrix;
}

export function getShortestPathDistance(adjM, startNode, endNode) {
  if (!Number.isInteger(startNode) || !Number.isInteger(endNode)) return null;
  const distanceMatrix = createShortestPathDistanceMatrix(adjM);
  return distanceMatrix[startNode]?.[endNode] ?? null;
}
