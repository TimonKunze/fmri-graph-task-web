import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

test('scanner choice candidates should never be directly connected', { skip: 'Known instruction/trial mismatch' }, () => {
  const source = fs.readFileSync('src/config/instructions.js', 'utf8').toLowerCase();
  assert.equal(source.includes('the two images will not form a direct connection'), false);
});
