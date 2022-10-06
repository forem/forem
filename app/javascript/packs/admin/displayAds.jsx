import { h, render } from 'preact';
import { Tags } from '../../display-ad/tags';

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function saveTags() {}

function loadForm() {
  const displayAdsTargetedTags = document.getElementById(
    'display-ad-targeted-tags',
  );

  render(<Tags onInput={saveTags} />, displayAdsTargetedTags);
}

document.ready.then(() => {
  // To Fix: loadForm is getting called twice.
  loadForm();
  // window.InstantClick.on('change', () => {
  if (document.getElementById('display-ad-form')) {
    loadForm();
  }
  // });
});
