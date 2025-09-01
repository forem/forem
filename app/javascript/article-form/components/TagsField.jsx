import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { locale } from '@utilities/locale';
import { useTagsField } from '../../hooks/useTagsField';
import { TagAutocompleteOption } from '@crayons/MultiSelectAutocomplete/TagAutocompleteOption';
import { TagAutocompleteSelection } from '@crayons/MultiSelectAutocomplete/TagAutocompleteSelection';
import { MultiSelectAutocomplete } from '@crayons';

/**
 * TagsField for the article form. Allows users to search and select up to 4 tags.
 *
 * @param {Function} onInput Callback to sync selections to article form state
 * @param {string} defaultValue Comma separated list of any currently selected tags
 * @param {Function} switchHelpContext Callback to switch the help context when the field is focused
 */
export const TagsField = ({ onInput, defaultValue, switchHelpContext }) => {
  const [topTags, setTopTags] = useState([]);
  const { defaultSelections, fetchSuggestions, syncSelections } = useTagsField({
    defaultValue,
    onInput,
  });

  useEffect(() => {
    fetch('/tags/suggest')
      .then((res) => res.json())
      .then((results) => setTopTags(results));
  }, []);

  return (
    <MultiSelectAutocomplete
      defaultValue={defaultSelections}
      fetchSuggestions={fetchSuggestions}
      staticSuggestions={topTags}
      staticSuggestionsHeading={
        <h2 className="c-autocomplete--multi__top-tags-heading">Top tags</h2>
      }
      labelText={locale('core.tags_field_label')}
      showLabel={false}
      placeholder={locale('core.tags_field_placeholder')}
      border={false}
      maxSelections={4}
      SuggestionTemplate={TagAutocompleteOption}
      SelectionTemplate={TagAutocompleteSelection}
      onSelectionsChanged={syncSelections}
      onFocus={switchHelpContext}
      inputId="tag-input"
      allowUserDefinedSelections={true}
    />
  );
};

TagsField.propTypes = {
  onInput: PropTypes.func.isRequired,
  defaultValue: PropTypes.string,
  switchHelpContext: PropTypes.func,
};
