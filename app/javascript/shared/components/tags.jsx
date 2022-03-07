/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
import { h } from 'preact';
import { useEffect, useMemo } from 'preact/hooks';
import PropTypes from 'prop-types';
import { useTagsField } from '../../hooks/useTagsField';
import { TagAutocompleteOption } from '../../article-form/components/TagAutocompleteOption';
import { TagAutocompleteSelection } from '../../article-form/components/TagAutocompleteSelection';
import { MultiSelectAutocomplete } from '@crayons';

export const Tags = ({
  defaultValue,
  listing,
  onInput,
  classPrefix,
  category,
  maxTags,
  name,
  onFocus,
}) => {
  const listingState = useMemo(
    () =>
      listing
        ? {
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
          }
        : null,
    [listing],
  );

  const { defaultSelections, topTags, fetchSuggestions, syncSelections } =
    useTagsField({ defaultValue, onInput });

  useEffect(() => {
    if (listingState && listingState.additionalTags) {
      // TODO: replace jobs with category
      const { jobs } = listingState.additionalTags;
      // Push in this way: { name: 'remote' }
      const newJobs = jobs.map((t) => ({ name: t }));
      topTags.push(...newJobs);
    }
  }, [topTags, listingState]);

  const fetchSuggestionsWithAdditionalTags = async (searchTerm) => {
    const suggestionsResult = await fetchSuggestions(searchTerm);
    const suggestedNames = suggestionsResult.map((t) => t.name);

    const additionalItems = topTags.filter((t) => t.name.includes(searchTerm));
    // Remove duplicates
    additionalItems.forEach((t) => {
      if (!suggestedNames.includes(t.name)) {
        suggestionsResult.push(t);
      }
    });
    return suggestionsResult;
  };

  return (
    <div className={`${classPrefix}__tagswrapper crayons-field`}>
      {listing && (
        <label htmlFor="Tags" class="crayons-field__label">
          Tags
        </label>
      )}
      <MultiSelectAutocomplete
        defaultValue={defaultSelections}
        fetchSuggestions={fetchSuggestionsWithAdditionalTags}
        staticSuggestions={topTags}
        staticSuggestionsHeading={
          <h2 className="crayons-article-form__top-tags-heading">Top tags</h2>
        }
        showLabel={false}
        placeholder={`Add up to ${maxTags} tags...`}
        border={true}
        maxSelections={maxTags}
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

Tags.propTypes = {
  defaultValue: PropTypes.string.isRequired,
  onInput: PropTypes.func.isRequired,
  maxTags: PropTypes.number.isRequired,
  classPrefix: PropTypes.string.isRequired,
  name: PropTypes.string,
  listing: PropTypes.bool,
  category: PropTypes.string,
  onFocus: PropTypes.func,
};
