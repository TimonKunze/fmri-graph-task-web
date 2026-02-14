import seedrandom from "seedrandom";

// ---------- Arrays ----------
export function arraysEqual(a1, a2) {
  return JSON.stringify(a1) === JSON.stringify(a2);
}

export function listsEqual(list1, list2) {
  if (list1.length !== list2.length) return false;
  for (let i = 0; i < list1.length; i++) {
    if (list1[i] !== list2[i]) return false;
  }
  return true;
}

export function addUniqueArray(targetArray, arrayToAdd) {
  const exists = targetArray.some(
    (el) => Array.isArray(el) && JSON.stringify(el) === JSON.stringify(arrayToAdd)
  );
  if (!exists) {
    targetArray.push(arrayToAdd);
    return true;
  }
  return false;
}

export function midpointShift(a, b) {
  return a.map((val, i) => (val - b[i]) / 2 + b[i]);
}

// ---------- Geometry ----------
export function shortenLine(x1, y1, x2, y2, shortenAmount) {
  const dx = x2 - x1;
  const dy = y2 - y1;
  const length = Math.sqrt(dx * dx + dy * dy);
  const ux = dx / length;
  const uy = dy / length;

  return [
    x1 + ux * shortenAmount,
    y1 + uy * shortenAmount,
    x2 - ux * shortenAmount,
    y2 - uy * shortenAmount,
  ];
}

// ---------- Randomization ----------
export function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

// ✅ deterministic shuffle (pass seed explicitly)
export function seededShuffleArray(array, seed = "") {
  const rng = seedrandom(seed);
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

export function generateBinaryArray(arrLen1, arrLen0 = null) {
  if (arrLen0 == null) {
    arrLen0 = arrLen1;
    if (arrLen1 % 2 !== 0) console.error("Alert: length should be an even number.");
  }
  return Array(arrLen1).fill(1).concat(Array(arrLen0).fill(0));
}

export function generateRandomBinaryList(arrLen1, arrLen0 = null) {
  return shuffleArray(generateBinaryArray(arrLen1, arrLen0));
}

export function randomIntFromInterval(min, max) {
  return Math.floor(Math.random() * (max - min + 1) + min);
}

// ---------- Type conversion ----------
export function nestedArrayToString(arr) {
  if (!Array.isArray(arr)) return String(arr);
  const stringArray = arr.map((el) => nestedArrayToString(el));
  return "[" + stringArray.join(", ") + "]";
}

export function JSON2CSV(objArray) {
  const array = typeof objArray !== "object" ? JSON.parse(objArray) : objArray;
  let result = "";
  const columns = [];

  // header
  let header = "";
  for (const row of array) {
    for (const key in row) {
      if (!columns.includes(key)) {
        columns.push(key);
        header += `"${String(key).replace(/"/g, '""')}",`;
      }
    }
  }
  result += header.slice(0, -1) + "\r\n";

  // rows
  for (const row of array) {
    let line = "";
    for (const col of columns) {
      let value = typeof row[col] === "undefined" ? "" : row[col];
      if (typeof value === "object") value = JSON.stringify(value);
      line += `"${String(value).replace(/"/g, '""')}",`;
    }
    result += line.slice(0, -1) + "\r\n";
  }
  return result;
}

// ---------- Output ----------
export function downloadFile(data, filename, type) {
  const file = new Blob([data], { type });
  const url = URL.createObjectURL(file);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  setTimeout(() => {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 0);
}

// ---------- Encoding ----------
export function decodeString(encoded) {
  if (encoded.length % 2 !== 0) throw new Error("Invalid Base16 encoded string length.");
  let decoded = "";
  for (let i = 0; i < encoded.length; i += 2) {
    decoded += String.fromCharCode(parseInt(encoded.substr(i, 2), 16));
  }
  return decoded;
}
