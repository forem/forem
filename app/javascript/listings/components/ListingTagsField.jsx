import { h } from 'preact';
import { useEffect, useMemo, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { useTagsField } from '../../hooks/useTagsField';
import { TagAutocompleteOption } from '@crayons/MultiSelectAutocomplete/TagAutocompleteOption';
import { TagAutocompleteSelection } from '@crayons/MultiSelectAutocomplete/TagAutocompleteSelection';
import { MultiSelectAutocomplete } from '@crayons';

export const ListingTagsField = ({
  defaultValue,
  onInput,
  categorySlug,
  name,
  onFocus,
}) => {
  const listingState = useMemo(
    () => ({
      additionalTags: {
        jobs: [
          'remote',
          'remoteoptional',
          'lgbtbenefits',
          'greencard',
          'senior',
          'junior',
          'intermediate',
          '401k',
          'fulltime',
          'contract',
          'temp',
        ],
        forhire: [
          'remote',
          'remoteoptional',
          'lgbtbenefits',
          'greencard',
          'senior',
          'junior',
          'intermediate',
          '401k',
          'fulltime',
          'contract',
          'temp',
        ],
        forsale: ['laptop', 'desktopcomputer', 'new', 'used'],
        events: ['conference', 'meetup'],
        collabs: ['paid', 'temp'],
      },
    }),
    [],
  );

  const { defaultSelections, fetchSuggestions, syncSelections } = useTagsField({
    defaultValue,
    onInput,
  });
  const [suggestedTags, setSuggestedTags] = useState([]);

  useEffect(() => {
    // Push in this way: { name: 'remote' }
    const categorySuggestedTags = (
      listingState.additionalTags[categorySlug] || []
    ).map((name) => ({ name }));
    setSuggestedTags(categorySuggestedTags);
  }, [listingState, categorySlug]);

  const fetchSuggestionsWithAdditionalTags = async (searchTerm) => {
    const fetchedSuggestions = await fetchSuggestions(searchTerm);
    const suggestedNames = fetchedSuggestions.map((t) => t.name);

    // Search in the suggestedTags array
    const additionalItems = suggestedTags.filter(
      (t) => t.name.startsWith(searchTerm) && !suggestedNames.includes(t.name),
    );
    // Join fetched and additional items
    const suggestionsResult = [...fetchedSuggestions, ...additionalItems];
    // Order suggestionsResult by name
    suggestionsResult.sort((a, b) => a.name.localeCompare(b.name));
    return suggestionsResult;
  };

  return (
    <div className="listingform__tagswrapper crayons-field">
      <MultiSelectAutocomplete
        defaultValue={defaultSelections}
        fetchSuggestions={fetchSuggestionsWithAdditionalTags}
        staticSuggestions={suggestedTags}
        staticSuggestionsHeading={
          <h2 className="c-autocomplete--multi__top-tags-heading">Top tags</h2>
        }
        labelText="Tags"
        placeholder="Add up to 8 tags..."
        maxSelections={8}
        SuggestionTemplate={TagAutocompleteOption}
        SelectionTemplate={TagAutocompleteSelection}
        onSelectionsChanged={syncSelections}
        inputId="tag-input"
        onFocus={onFocus}
      />
      {/* Hidden input to store the selected tags and be sent via form data */}
      {name && <input type="hidden" name={name} value={defaultValue} />}
    </div>
  );
};

ListingTagsField.propTypes = {
  defaultValue: PropTypes.string.isRequired,
  categorySlug: PropTypes.string,
  name: PropTypes.string,
  onInput: PropTypes.func.isRequired,
  onFocus: PropTypes.func,
};
