import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { TagAutocompleteOption } from './TagAutocompleteOption';
import { TagAutocompleteSelection } from './TagAutocompleteSelection';
import { MultiSelectAutocomplete } from '@crayons';
import { fetchSearch } from '@utilities/search';

//TODO:

// Check how listings tags are affected
// Docs
// Styles clean up
// Storybook updates

export const TagsField = ({ onInput, defaultValue, switchHelpContext }) => {
  const [defaultSelections, setDefaultSelections] = useState([]);
  const [topTags, setTopTags] = useState([]);

  useEffect(() => {
    // If the default selections have not already been populated, fetch the tag data
    if (defaultValue && defaultValue !== '' && defaultSelections.length === 0) {
      // The article stores tags as a comma separated string
      const tagNames = defaultValue.split(', ');

      // We need to fetch the full tag data to display the rich UI
      const tagRequests = tagNames.map((tagName) =>
        fetchSearch('tags', { name: tagName }).then(
          ({ result }) => result[0] || { name: tagName },
        ),
      );

      Promise.all(tagRequests).then((data) => {
        setDefaultSelections(data);
      });
    }
  }, [defaultValue, defaultSelections.length]);

  useEffect(() => {
    window
      .fetch('/tags/suggest')
      .then((res) => res.json())
      .then((results) => setTopTags(results));
  }, []);

  const syncSelections = (selections = []) => {
    const selectionsString = selections
      .map((selection) => selection.name)
      .join(', ');
    onInput(selectionsString);
  };

  const fetchSuggestions = (searchTerm) =>
    fetchSearch('tags', { name: searchTerm }).then(
      (response) => response.result,
    );

  return (
    <MultiSelectAutocomplete
      defaultValue={defaultSelections}
      fetchSuggestions={fetchSuggestions}
      staticSuggestions={topTags}
      staticSuggestionsHeading={
        <h2 className="crayons-article-form__top-tags-heading">Top tags</h2>
      }
      labelText="Add up to 4 tags"
      showLabel={false}
      placeholder="Add up to 4 tags..."
      border={false}
      maxSelections={4}
      SuggestionTemplate={TagAutocompleteOption}
      SelectionTemplate={TagAutocompleteSelection}
      onSelectionsChanged={syncSelections}
      onFocus={switchHelpContext}
      inputId="tag-input"
    />
  );
};

// TODO: needed by other components (move)
export const DEFAULT_TAG_FORMAT = '[0-9A-Za-z, ]+';

// export const TagsField = ({
//   defaultValue,
//   onInput,
//   switchHelpContext,
//   tagFormat = DEFAULT_TAG_FORMAT,
// }) => {
//   return (
//     <div className="crayons-article-form__tagsfield">
//       <Tags
//         defaultValue={defaultValue}
//         maxTags={4}
//         onInput={onInput}
//         onFocus={switchHelpContext}
//         classPrefix="crayons-article-form"
//         fieldClassName="crayons-textfield crayons-textfield--ghost ff-monospace"
//         pattern={tagFormat}
//       />
//     </div>
//   );
// };

// TagsField.propTypes = {
//   onInput: PropTypes.func.isRequired,
//   defaultValue: PropTypes.string.isRequired,
//   switchHelpContext: PropTypes.func.isRequired,
// };

// TagsField.displayName = 'TagsField';
