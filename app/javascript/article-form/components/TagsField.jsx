import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { TagAutocompleteOption } from './TagAutocompleteOption';
import { TagAutocompleteSelection } from './TagAutocompleteSelection';
import { MultiSelectAutocomplete } from '@crayons';
import { fetchSearch } from '@utilities/search';

//TODO:

// Default value - need to fetch tags details to display correctly
// Limit number that can be added
// Switch help context

export const TagsField = ({ onInput, defaultValue }) => {
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
      fetchSuggestions={fetchSuggestions}
      placeholder="Add tags..."
      border={false}
      SuggestionTemplate={TagAutocompleteOption}
      SelectionTemplate={TagAutocompleteSelection}
      onSelectionsChanged={syncSelections}
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
