import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { Tags } from '../../shared/components/tags';
import { MultiSelectAutocomplete } from '@crayons';
import { fetchSearch } from '@utilities/search';

export const TagsField = () => {
  const fetchSuggestions = (searchTerm) =>
    fetchSearch('tags', { name: searchTerm }).then(
      (response) => response.result,
    );

  return (
    <MultiSelectAutocomplete
      fetchSuggestions={fetchSuggestions}
      placeholder="Add tags..."
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
