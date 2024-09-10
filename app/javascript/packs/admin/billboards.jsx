import { h, render } from 'preact';
import { Tags } from '../../billboard/tags';

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

/**
 * A callback that sets the hidden 'js-tags-textfield' with the selection string that was chosen via the
 * MultiSelectAutocomplete component.
 *
 * @param {String} selectionString The selected tags represented as a string (e.g. "webdev, git, career")
 */
function saveTags(selectionString) {
  document.getElementsByClassName('js-tags-textfield')[0].value =
    selectionString;
}

/**
 * Shows and Renders a Tags preact component for the Targeted Tag(s) field
 */
function showPrecisionFields() {
  const billboardsTargetedTags = document.getElementById(
    'billboard-targeted-tags',
  );

  if (billboardsTargetedTags) {
    billboardsTargetedTags.classList.remove('hidden');
    render(
      <Tags onInput={saveTags} defaultValue={defaultTagValues()} />,
      billboardsTargetedTags,
    );
  }

  const billboardPrecisionElements = document.querySelectorAll(
    '.billboard-requires-precision-targeting',
  );

  billboardPrecisionElements.forEach((element) => {
    element?.classList.remove('hidden');
  });
}

/**
 * Hides the Targeted Tag(s) field
 */
function hidePrecisionFields() {
  const billboardsTargetedTags = document.getElementById(
    'billboard-targeted-tags',
  );

  billboardsTargetedTags?.classList.add('hidden');

  const billboardPrecisionElements = document.querySelectorAll(
    '.billboard-requires-precision-targeting',
  );

  billboardPrecisionElements.forEach((element) => {
    element?.classList.add('hidden');
  });
}

/**
 * Clears the content (i.e. value) of the hidden tags textfield
 */
function clearTagList() {
  const hiddenTagsField =
    document.getElementsByClassName('js-tags-textfield')[0];

  hiddenTagsField.value = ' ';
}

/**
 * Returns the value of the hidden text field to eventually pass as
 * default values to the MultiSelectAutocomplete component.
 */
function defaultTagValues() {
  let defaultValue = '';
  const hiddenTagsField =
    document.getElementsByClassName('js-tags-textfield')[0];

  if (hiddenTagsField) {
    defaultValue = hiddenTagsField.value.trim();
  }

  return defaultValue;
}

function displayUserTargets() {
  const userTargetFields = document.getElementsByClassName('js-user-target');
  Array.from(userTargetFields).forEach((field) => {
    field.parentElement.classList.remove('hidden');
  });
}

function hideUserTargets() {
  const userTargetFields = document.getElementsByClassName('js-user-target');
  Array.from(userTargetFields).forEach((field) => {
    field.parentElement.classList.add('hidden');
  });
}

function clearUserTargetSelection() {
  const userTargetSelects = document.getElementsByClassName('js-user-target');
  Array.from(userTargetSelects).forEach((select) => {
    select.value = '';
  });
}

/**
 * Shows and Renders Exclude Article IDs group
 */
function showExcludeIds() {
  const excludeField = document.getElementsByClassName(
    'js-exclude-ids-textfield',
  )[0].parentElement;
  excludeField?.classList.remove('hidden');
}

/**
 * Hides the Exclude Article IDs group
 */
function hideExcludeIds() {
  const excludeField = document.getElementsByClassName(
    'js-exclude-ids-textfield',
  )[0].parentElement;
  excludeField?.classList.add('hidden');
}

/**
 * Clears the content (i.e. value) of the Exclude Article IDs group
 */
function clearExcludeIds() {
  const excludeField = document.getElementsByClassName(
    'js-exclude-ids-textfield',
  )[0];
  if (excludeField) {
    excludeField.value = '';
  }
}

/**
 * Shows and sets up the Targeted Tag(s) field if the placement area value is "post_comments".
 * Listens for change events on the select placement area dropdown
 * and shows and hides the Targeted Tag(s) appropriately.
 */
document.ready.then(() => {
  const select = document.getElementsByClassName('js-placement-area')[0];
  const articleSpecificPlacement = [
    'post_comments',
    'post_sidebar',
    'post_fixed_bottom',
  ];
  const targetedTagPlacements = [
    'post_fixed_bottom',
    'post_comments',
    'post_sidebar',
    'sidebar_right',
    'sidebar_right_second',
    'sidebar_right_third',
    'feed_first',
    'feed_second',
    'feed_third',
  ];

  if (targetedTagPlacements.includes(select.value)) {
    showPrecisionFields();
  }

  select.addEventListener('change', (event) => {
    if (targetedTagPlacements.includes(event.target.value)) {
      showPrecisionFields();
    } else {
      hidePrecisionFields();
      clearTagList();
    }
  });

  if (articleSpecificPlacement.includes(select.value)) {
    showExcludeIds();
  }

  select.addEventListener('change', (event) => {
    if (articleSpecificPlacement.includes(event.target.value)) {
      showExcludeIds();
    } else {
      hideExcludeIds();
      clearExcludeIds();
    }
  });

  const userRadios = document.querySelectorAll('input[name=display_to]');
  userRadios.forEach((radio) => {
    radio.addEventListener('change', (event) => {
      if (event.target.value == 'logged_in') {
        displayUserTargets();
      } else {
        hideUserTargets();
        clearUserTargetSelection();
      }
    });
  });
});
