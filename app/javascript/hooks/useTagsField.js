import { useEffect, useState } from 'preact/hooks';
import algoliasearch from 'algoliasearch/lite'
import { fetchSearch } from '@utilities/search';


/**
 * Custom hook to manage the logic for the tags-fields based on the `MultiSelectAutocomplete` component
 *
 * @param {string} defaultValue The default value for the tags field, needs to be a comma separated string
 * @param {Function} onInput The function to call when the input changes
 * @returns {Object}
 * An object containing `defaultSelections` list, `fetchSuggestions` function, and `syncSelections` function
 */
export const useTagsField = ({ defaultValue, onInput }) => {
  const useFetchSearch = document.body.dataset.algoliaId?.length === 0;
  let algoliaIndex;
  if (!useFetchSearch) {
    const env = document.querySelector('meta[name="environment"]')?.content;
    const {algoliaId, algoliaSearchKey} = document.body.dataset;
    const algoliaClient = algoliasearch(algoliaId, algoliaSearchKey);
    algoliaIndex = algoliaClient.initIndex(`Tag_${env}`);
  }

  const [defaultSelections, setDefaultSelections] = useState([]);
  const [defaultsLoaded, setDefaultsLoaded] = useState(false);

  useEffect(() => {
    // Previously selected tags are passed as a plain comma separated string
    // Fetching further tag data allows us to display a richer UI
    // This fetch only happens once on first component load
    if (defaultValue && defaultValue !== '' && !defaultsLoaded) {
      const tagNames = defaultValue.split(', ');

      const tagRequests = tagNames.map((tagName) => 
        (useFetchSearch ? 
          fetchSearch('tags', { name: tagName }).then(({ result = [] }) => {
            const [potentialMatch = {}] = result;
            return potentialMatch.name === tagName
              ? potentialMatch
              : { name: tagName };
          }) :
          algoliaIndex.search(tagName).then(({ hits }) => {
            const [potentialMatch = {}] = hits;
            return potentialMatch.name === tagName
              ? potentialMatch
              : { name: tagName };
          })
        )
      );

      Promise.all(tagRequests).then((data) => {
        setDefaultSelections(data);
      });
    }
    setDefaultsLoaded(true);
  }, [defaultValue, defaultsLoaded, useFetchSearch]);

  /**
   * Converts the array of selected items into a plain string,
   * and ensures the `onInput` callback is triggered with the new tags list
   * @param {Array} selections
   */
  const syncSelections = (selections = []) => {
    const selectionsString = selections
      .map((selection) => selection.name)
      .join(', ');
    onInput(selectionsString);
  };

  /**
   * Fetches tags for a given search term
   *
   * @param {string} searchTerm The text to search for
   * @returns {Promise} Promise which resolves to the tag search results
   */
  const fetchSuggestions = (searchTerm) => 
    (useFetchSearch ? 
      fetchSearch('tags', { name: searchTerm }).then(
        (response) => response.result,
      ) : 
      algoliaIndex.search(searchTerm, {
        facetFilters: ["supported:true"]
      }).then(
        (response) => response.hits,
      )
    );

  return {
    defaultSelections,
    fetchSuggestions,
    syncSelections,
  };
};
