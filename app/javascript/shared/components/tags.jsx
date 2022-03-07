/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
import { h } from 'preact';
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
}) => {
  const listingState = listing
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
    : null;

  // search(query) {
  //   if (query === '') {
  //     return this.fetchTopTagSuggestions();
  //   }
  //   this.setState({ showingTopTags: false });

  //   const { listing } = this.props;

  //   const dataHash = { name: query };
  //   const responsePromise = fetchSearch('tags', dataHash);

  //   return responsePromise.then((response) => {
  //     if (listing === true) {
  //       const { additionalTags } = this.state;
  //       const { category } = this.props;
  //       const additionalItems = (additionalTags[category] || []).filter((t) =>
  //         t.includes(query),
  //       );
  //       const resultsArray = response.result;
  //       additionalItems.forEach((t) => {
  //         if (!resultsArray.includes(t)) {
  //           resultsArray.push({ name: t });
  //         }
  //       });
  //     }
  //     // updates searchResults array according to what is being typed by user
  //     // allows user to choose a tag when they've typed the partial or whole word
  //     this.setState({
  //       searchResults: response.result.filter(
  //         (t) => t.name === query || !this.selected.includes(t.name),
  //       ),
  //     });
  //   });
  // }

  const { defaultSelections, topTags, fetchSuggestions, syncSelections } =
    useTagsField({ defaultValue, onInput });

  return (
    <div className={`${classPrefix}__tagswrapper crayons-field`}>
      {listing && (
        <label htmlFor="Tags" class="crayons-field__label">
          Tags
        </label>
      )}
      <MultiSelectAutocomplete
        defaultValue={defaultSelections}
        fetchSuggestions={fetchSuggestions}
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
  fieldClassName: PropTypes.string.isRequired,
  listing: PropTypes.bool,
  category: PropTypes.string,
  onFocus: PropTypes.func.isRequired,
  pattern: PropTypes.string.isRequired,
};
