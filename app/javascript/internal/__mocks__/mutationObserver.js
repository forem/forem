// Sourced from https://github.com/stimulusjs/stimulus/issues/34
// and https://shime.sh/testing-stimulus

// Setup MutationObserver shim since jsdom doesn't
// support it out of the box.

import { readFileSync } from 'fs';
import { resolve } from 'path';

const shim = readFileSync(
  resolve(
    'node_modules',
    'mutationobserver-shim',
    'dist',
    'mutationobserver.min.js',
  ),
  { encoding: 'utf-8' },
);

const script = window.document.createElement('script');
script.textContent = shim;

window.document.body.appendChild(script);
