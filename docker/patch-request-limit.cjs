'use strict';

const fs = require('node:fs');

const targetPath = '/app/packages/server/dist/app.js';
const original = 'app.use(express.json());';
const patched = "app.use(express.json({ limit: '1mb' }));";

const source = fs.readFileSync(targetPath, 'utf8');
const occurrences = source.split(original).length - 1;

if (occurrences !== 1) {
  throw new Error(
    `Expected exactly one default JSON parser in ${targetPath}, found ${occurrences}. ` +
      'The upstream image may have changed, so the local patch was not applied.'
  );
}

const result = source.replace(original, patched);
fs.writeFileSync(targetPath, result, 'utf8');

if (!fs.readFileSync(targetPath, 'utf8').includes(patched)) {
  throw new Error(`Failed to verify the request-limit patch in ${targetPath}.`);
}

fs.unlinkSync(__filename);
console.log('Set the AIOStreams JSON request limit to 1mb.');
