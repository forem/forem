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
function showTagsField() {
  const displayAdsTargetedTags = document.getElementById(
    'display-ad-targeted-tags',
  );
  displayAdsTargetedTags.classList.remove('hidden');

  const defaultTagValues = getDefaultTagValues();

  if (displayAdsTargetedTags) {
    render(
      <Tags onInput={saveTags} defaultValue={defaultTagValues} />,
      displayAdsTargetedTags,
    );
  }
}

function hideTagsField() {
  const displayAdsTargetedTags = document.getElementById(
    'display-ad-targeted-tags',
  );

  displayAdsTargetedTags.classList.add('hidden');
}

function clearTagList() {
  const hiddenTagsField =
    document.getElementsByClassName('js-tags-textfield')[0];

  hiddenTagsField.value = ' ';
}

function getDefaultTagValues() {
  let defaultValue = '';
  const hiddenTagsField =
    document.getElementsByClassName('js-tags-textfield')[0];

  if (hiddenTagsField) {
    defaultValue = hiddenTagsField.value.replaceAll(' ', ', ');
  }

  return defaultValue;
}

document.ready.then(() => {
  const select = document.getElementsByClassName('js-placement-area')[0];

  if (select.value === 'post_comments') {
    showTagsField();
  }

  select.addEventListener('change', (event) => {
    if (event.target.value === 'post_comments') {
      showTagsField();
    } else {
      hideTagsField();
      clearTagList();
    }
  });
});
