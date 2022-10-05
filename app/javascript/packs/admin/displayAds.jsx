import { h, render } from 'preact';
import { MultiSelectAutocomplete } from '@crayons';

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadForm() {
  const displayAdsTargetedTags = document.getElementById(
    'display-ad-targeted-tags',
  );
  render(
    <MultiSelectAutocomplete
      border
      fetchSuggestions={() => {}}
      labelText="Targeted Tag(s)"
      maxSelections={10}
      placeholder="Add up to 10 tags"
      showLabel
      staticSuggestions={[
        {
          name: '#javascript',
        },
        {
          name: '#beginner',
        },
        {
          name: '#codenewbie',
        },
      ]}
      staticSuggestionsHeading="Top Tags"
    />,
    displayAdsTargetedTags,
  );
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
