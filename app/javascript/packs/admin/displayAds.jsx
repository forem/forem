import { h, render } from 'preact';
import { Tags } from '../../display-ad/tags';

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function saveTags(selectionString) {
  document.getElementsByClassName('js-tags-textfield')[0].value =
    selectionString;
}

function loadTagsField() {
  let defaultValue = '';
  const hiddenTagsField =
    document.getElementsByClassName('js-tags-textfield')[0];

  if (hiddenTagsField) {
    defaultValue = hiddenTagsField.value.replaceAll(' ', ', ');
  }

  const displayAdsTargetedTags = document.getElementById(
    'display-ad-targeted-tags',
  );

  if (displayAdsTargetedTags) {
    render(
      <Tags onInput={saveTags} defaultValue={defaultValue} />,
      displayAdsTargetedTags,
    );
  }
}

function hideAndClearTags() {
  // console.log("hide and clear tasg")
}

document.ready.then(() => {
  const select = document.getElementsByClassName('js-placement-area')[0];
  select.addEventListener('change', (event) => {
    if (event.target.value === 'post_comments') {
      loadTagsField();
    } else {
      hideAndClearTags();
    }
  });
});
