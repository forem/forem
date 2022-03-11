import { h } from 'preact';
import { useEffect, useMemo, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { useTagsField } from '../../hooks/useTagsField';
import { TagAutocompleteOption } from '../../article-form/components/TagAutocompleteOption';
import { TagAutocompleteSelection } from '../../article-form/components/TagAutocompleteSelection';
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

  const { defaultSelections, topTags, fetchSuggestions, syncSelections } =
    useTagsField({ defaultValue, onInput });
  const [topTagsWithAdditional, setTopTagsWithAdditional] = useState([
    ...topTags,
  ]);

  useEffect(() => {
    if (listingState && listingState.additionalTags) {
      const newTagsForSelectedCategory =
        listingState.additionalTags[categorySlug] || [];
      // Push in this way: { name: 'remote' }
      const formattedNewTagsForSelectedCategory =
        newTagsForSelectedCategory.map((name) => ({ name }));
      setTopTagsWithAdditional([
        ...topTags,
        ...formattedNewTagsForSelectedCategory,
      ]);
    }
  }, [topTags, listingState, categorySlug]);

  const fetchSuggestionsWithAdditionalTags = async (searchTerm) => {
    const suggestionsResult = await fetchSuggestions(searchTerm);
    const suggestedNames = suggestionsResult.map((t) => t.name);

    // Search in the topTagsWithAdditional array
    const additionalItems = topTagsWithAdditional.filter((t) =>
      t.name.startsWith(searchTerm),
    );
    // Remove duplicates
    additionalItems.forEach((t) => {
      if (!suggestedNames.includes(t.name)) {
        suggestionsResult.push(t);
      }
    });
    return suggestionsResult;
  };

  return (
    <div className="listingform__tagswrapper crayons-field">
      <MultiSelectAutocomplete
        defaultValue={defaultSelections}
        fetchSuggestions={fetchSuggestionsWithAdditionalTags}
        staticSuggestions={topTagsWithAdditional}
        staticSuggestionsHeading={
          <h2 className="crayons-article-form__top-tags-heading">Top tags</h2>
        }
        labelText="Tags"
        showLabel
        placeholder="Add up to 8 tags..."
        border={true}
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
