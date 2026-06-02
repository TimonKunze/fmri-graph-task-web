import { CONFIG } from "../config.js";
import { COLORS } from "../config/colors.js";

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error(`Failed to load image: ${src}`));
    img.src = src;
  });
}

function computeBeeAngle(startPos, endPos) {
  const angle = Math.atan2(endPos[1] - startPos[1], endPos[0] - startPos[0]) + Math.PI;
  const dirFlags = [startPos[0] < endPos[0], startPos[1] < endPos[1]].toString();

  if (
    dirFlags === [true, true].toString() ||
    dirFlags === [true, false].toString()
  ) {
    return angle - (3 * Math.PI) / 2;
  }

  if (
    dirFlags === [false, false].toString() ||
    dirFlags === [false, true].toString()
  ) {
    return angle + (3 * Math.PI) / 2;
  }

  return angle;
}

function distance(a, b) {
  return Math.hypot(b[0] - a[0], b[1] - a[1]);
}

function createDownload(blob, fileName) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function createFrameFileName(baseName, frameIndex) {
  return `${baseName}_${String(frameIndex).padStart(4, "0")}.png`;
}

function buildCrc32Table() {
  const table = new Uint32Array(256);

  for (let i = 0; i < 256; i += 1) {
    let c = i;
    for (let j = 0; j < 8; j += 1) {
      c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c >>> 0;
  }

  return table;
}

const CRC32_TABLE = buildCrc32Table();

function crc32(bytes) {
  let crc = 0xffffffff;

  for (let i = 0; i < bytes.length; i += 1) {
    crc = CRC32_TABLE[(crc ^ bytes[i]) & 0xff] ^ (crc >>> 8);
  }

  return (crc ^ 0xffffffff) >>> 0;
}

function dateToDosDateTime(date = new Date()) {
  const year = Math.max(1980, date.getFullYear());
  const dosTime =
    ((date.getHours() & 0x1f) << 11) |
    ((date.getMinutes() & 0x3f) << 5) |
    ((Math.floor(date.getSeconds() / 2)) & 0x1f);
  const dosDate =
    (((year - 1980) & 0x7f) << 9) |
    (((date.getMonth() + 1) & 0x0f) << 5) |
    (date.getDate() & 0x1f);

  return { dosDate, dosTime };
}

function writeUint16(view, offset, value) {
  view.setUint16(offset, value, true);
}

function writeUint32(view, offset, value) {
  view.setUint32(offset, value, true);
}

function createStoredZip(entries) {
  const encoder = new TextEncoder();
  const now = dateToDosDateTime();
  const localParts = [];
  const centralParts = [];
  let offset = 0;
  let centralSize = 0;

  for (const entry of entries) {
    const nameBytes = encoder.encode(entry.name);
    const dataBytes = entry.bytes;
    const crc = crc32(dataBytes);

    const localHeader = new ArrayBuffer(30 + nameBytes.length);
    const localView = new DataView(localHeader);
    writeUint32(localView, 0, 0x04034b50);
    writeUint16(localView, 4, 20);
    writeUint16(localView, 6, 0);
    writeUint16(localView, 8, 0);
    writeUint16(localView, 10, now.dosTime);
    writeUint16(localView, 12, now.dosDate);
    writeUint32(localView, 14, crc);
    writeUint32(localView, 18, dataBytes.length);
    writeUint32(localView, 22, dataBytes.length);
    writeUint16(localView, 26, nameBytes.length);
    writeUint16(localView, 28, 0);
    new Uint8Array(localHeader, 30).set(nameBytes);

    localParts.push(new Uint8Array(localHeader), dataBytes);

    const centralHeader = new ArrayBuffer(46 + nameBytes.length);
    const centralView = new DataView(centralHeader);
    writeUint32(centralView, 0, 0x02014b50);
    writeUint16(centralView, 4, 20);
    writeUint16(centralView, 6, 20);
    writeUint16(centralView, 8, 0);
    writeUint16(centralView, 10, 0);
    writeUint16(centralView, 12, now.dosTime);
    writeUint16(centralView, 14, now.dosDate);
    writeUint32(centralView, 16, crc);
    writeUint32(centralView, 20, dataBytes.length);
    writeUint32(centralView, 24, dataBytes.length);
    writeUint16(centralView, 28, nameBytes.length);
    writeUint16(centralView, 30, 0);
    writeUint16(centralView, 32, 0);
    writeUint16(centralView, 34, 0);
    writeUint16(centralView, 36, 0);
    writeUint32(centralView, 38, 0);
    writeUint32(centralView, 42, offset);
    new Uint8Array(centralHeader, 46).set(nameBytes);

    centralParts.push(new Uint8Array(centralHeader));

    const localSize = 30 + nameBytes.length + dataBytes.length;
    offset += localSize;
    centralSize += 46 + nameBytes.length;
  }

  const endHeader = new ArrayBuffer(22);
  const endView = new DataView(endHeader);
  writeUint32(endView, 0, 0x06054b50);
  writeUint16(endView, 4, 0);
  writeUint16(endView, 6, 0);
  writeUint16(endView, 8, entries.length);
  writeUint16(endView, 10, entries.length);
  writeUint32(endView, 12, centralSize);
  writeUint32(endView, 16, offset);
  writeUint16(endView, 20, 0);

  return new Blob([...localParts, ...centralParts, new Uint8Array(endHeader)], {
    type: "application/zip",
  });
}

function drawFrame(ctx, state) {
  const {
    width,
    height,
    backgroundColor,
    startPos,
    endPos,
    currentPos,
    startImg,
    endImg,
    movingImgA,
    movingImgB,
    nodeSize,
    movingFigureSize,
    showSearchLabel,
    flapIndex,
    totalFrames,
  } = state;

  ctx.clearRect(0, 0, width, height);
  ctx.fillStyle = backgroundColor;
  ctx.fillRect(0, 0, width, height);

  if (showSearchLabel) {
    ctx.fillStyle = COLORS.envText;
    ctx.font = "38px Courier New";
    ctx.fillText("Search", 20, 42);
  }

  ctx.drawImage(startImg, startPos[0] - nodeSize / 2, startPos[1] - nodeSize / 2, nodeSize, nodeSize);
  ctx.drawImage(endImg, endPos[0] - nodeSize / 2, endPos[1] - nodeSize / 2, nodeSize, nodeSize);

  const hideMovingFigure = flapIndex < 2 || flapIndex >= totalFrames - 2;
  if (!hideMovingFigure) {
    const movingImg = flapIndex % 8 < 4 ? movingImgA : movingImgB;
    const beeAngle = computeBeeAngle(startPos, endPos);

    ctx.save();
    ctx.translate(currentPos[0], currentPos[1]);
    ctx.rotate(7 * Math.PI / 180);
    ctx.rotate(beeAngle);
    ctx.drawImage(
      movingImg,
      -movingFigureSize / 2,
      -movingFigureSize / 2,
      movingFigureSize,
      movingFigureSize
    );
    ctx.restore();
  }
}

async function exportCanvasFrames(canvas, renderFrame, totalFrames, outputBaseName, zipFileName, statusEl) {
  const entries = [];

  for (let frameIndex = 0; frameIndex < totalFrames; frameIndex += 1) {
    renderFrame(frameIndex);

    const blob = await new Promise((resolve, reject) => {
      canvas.toBlob((nextBlob) => {
        if (nextBlob) {
          resolve(nextBlob);
        } else {
          reject(new Error("Failed to export one of the PNG frames."));
        }
      }, "image/png");
    });

    const bytes = new Uint8Array(await blob.arrayBuffer());
    entries.push({
      name: createFrameFileName(outputBaseName, frameIndex),
      bytes,
    });

    if (statusEl) {
      statusEl.textContent = `Exporting PNG frames… ${frameIndex + 1} / ${totalFrames}`;
    }
  }

  const zipBlob = createStoredZip(entries);
  createDownload(zipBlob, zipFileName);
}

export async function runSingleTrialExporter() {
  const exportConfig = CONFIG.singleTrialExport;
  const root = document.querySelector("#app") ?? document.body;
  root.innerHTML = "";

  const container = document.createElement("div");
  container.style.maxWidth = "1040px";
  container.style.margin = "0 auto";
  container.style.padding = "32px 20px 48px";
  container.style.fontFamily = "system-ui, sans-serif";
  container.innerHTML = `
    <h1 style="margin:0 0 12px;">Single Trial Export</h1>
    <p style="margin:0 0 20px; line-height:1.5;">
      This mode renders one flight animation with the same canvas size, background color, and stimulus sizes as the experiment.
      Press the export button to download one ZIP file containing numbered PNG frames.
    </p>
    <div id="single-trial-export-status" style="margin:0 0 16px; color:#444;"></div>
    <div style="display:flex; gap:24px; flex-wrap:wrap; align-items:flex-start;">
      <canvas id="single-trial-export-canvas" width="${exportConfig.canvasSize[0]}" height="${exportConfig.canvasSize[1]}" style="border:1px solid #d6d6d6; max-width:min(100%, ${exportConfig.canvasSize[0]}px); height:auto;"></canvas>
      <div style="display:flex; flex-direction:column; gap:12px; min-width:220px;">
        <button id="single-trial-preview" type="button">Preview animation</button>
        <button id="single-trial-export" type="button">Export ZIP of PNG frames</button>
      </div>
    </div>
  `;
  root.appendChild(container);

  const statusEl = container.querySelector("#single-trial-export-status");
  const previewBtn = container.querySelector("#single-trial-preview");
  const exportBtn = container.querySelector("#single-trial-export");
  const canvas = container.querySelector("#single-trial-export-canvas");
  const ctx = canvas.getContext("2d");

  const [startImg, endImg, movingImgA, movingImgB] = await Promise.all([
    loadImage(exportConfig.startStimulusPath),
    loadImage(exportConfig.endStimulusPath),
    loadImage(exportConfig.movingFigurePath),
    loadImage(exportConfig.movingFigureMirroredPath),
  ]);

  const travelDistance = distance(exportConfig.startPos, exportConfig.endPos);
  const travelFrames = Math.max(1, Math.ceil(travelDistance / exportConfig.speed));
  const totalFrames = travelFrames + Math.max(0, Number(exportConfig.holdFrames ?? 0));

  const state = {
    width: exportConfig.canvasSize[0],
    height: exportConfig.canvasSize[1],
    backgroundColor: exportConfig.backgroundColor,
    startPos: exportConfig.startPos,
    endPos: exportConfig.endPos,
    currentPos: [...exportConfig.startPos],
    startImg,
    endImg,
    movingImgA,
    movingImgB,
    nodeSize: exportConfig.nodeSize,
    movingFigureSize: exportConfig.movingFigureSize,
    showSearchLabel: Boolean(exportConfig.showSearchLabel),
    flapIndex: 0,
    totalFrames,
  };

  const renderFrame = (frameIndex) => {
    const progress = Math.min(frameIndex, travelFrames) / travelFrames;
    state.currentPos = [
      exportConfig.startPos[0] + (exportConfig.endPos[0] - exportConfig.startPos[0]) * progress,
      exportConfig.startPos[1] + (exportConfig.endPos[1] - exportConfig.startPos[1]) * progress,
    ];
    state.flapIndex = frameIndex;
    drawFrame(ctx, state);
  };

  renderFrame(0);

  previewBtn.addEventListener("click", async () => {
    previewBtn.disabled = true;
    exportBtn.disabled = true;
    statusEl.textContent = "Previewing animation…";

    for (let frameIndex = 0; frameIndex < totalFrames; frameIndex += 1) {
      renderFrame(frameIndex);
      await new Promise((resolve) => setTimeout(resolve, 1000 / exportConfig.fps));
    }

    renderFrame(0);
    statusEl.textContent = "Preview finished.";
    previewBtn.disabled = false;
    exportBtn.disabled = false;
  });

  exportBtn.addEventListener("click", async () => {
    previewBtn.disabled = true;
    exportBtn.disabled = true;
    statusEl.textContent = "Building ZIP of PNG frames…";

    try {
      renderFrame(0);
      await exportCanvasFrames(
        canvas,
        renderFrame,
        totalFrames,
        exportConfig.outputBaseName ?? "single-trial-export",
        exportConfig.zipFileName ?? "single-trial-export.zip",
        statusEl
      );
      renderFrame(0);
      statusEl.textContent = `ZIP exported as ${exportConfig.zipFileName ?? "single-trial-export.zip"}.`;
    } catch (error) {
      statusEl.textContent = error instanceof Error ? error.message : String(error);
    } finally {
      previewBtn.disabled = false;
      exportBtn.disabled = false;
    }
  });
}
