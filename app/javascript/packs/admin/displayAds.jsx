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

function loadTagsField() {
  const displayAdsTargetedTags = document.getElementById(
    'display-ad-targeted-tags',
  );

  if (displayAdsTargetedTags) {
    render(<Tags onInput={saveTags} />, displayAdsTargetedTags);
  }
}

document.ready.then(() => {
  loadTagsField();
});
