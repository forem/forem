import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { TagAutocompleteOption } from './TagAutocompleteOption';
import { TagAutocompleteSelection } from './TagAutocompleteSelection';
import { MultiSelectAutocomplete } from '@crayons';
import { fetchSearch } from '@utilities/search';

/**
 * TagsField for the article form. Allows users to search and select up to 4 tags.
 *
 * @param {Function} onInput Callback to sync selections to article form state
 * @param {string} defaultValue Comma separated list of any currently selected tags
 * @param {Function} switchHelpContext Callback to switch the help context when the field is focused
 */
export const TagsField = ({ onInput, defaultValue, switchHelpContext }) => {
  const [defaultSelections, setDefaultSelections] = useState([]);
  const [defaultsLoaded, setDefaultsLoaded] = useState(false);
  const [topTags, setTopTags] = useState([]);

  useEffect(() => {
    fetch('/tags/suggest')
      .then((res) => res.json())
      .then((results) => setTopTags(results));
  }, []);

  useEffect(() => {
    // Previously selected tags are passed as a plain comma separated string
    // Fetching further tag data allows us to display a richer UI
    // This fetch only happens once on first component load
    if (defaultValue && defaultValue !== '' && !defaultsLoaded) {
      const tagNames = defaultValue.split(', ');

      const tagRequests = tagNames.map((tagName) =>
        fetchSearch('tags', { name: tagName }).then(({ result = [] }) => {
          const [potentialMatch = {}] = result;
          return potentialMatch.name === tagName
            ? potentialMatch
            : { name: tagName };
        }),
      );

      Promise.all(tagRequests).then((data) => {
        setDefaultSelections(data);
      });
    }
    setDefaultsLoaded(true);
  }, [defaultValue, defaultsLoaded]);

  // Converts the array of selected items into a plain string to be saved in the article form
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

TagsField.propTypes = {
  onInput: PropTypes.func.isRequired,
  defaultValue: PropTypes.string,
  switchHelpContext: PropTypes.func,
};
