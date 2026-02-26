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
  const { defaultSelections, fetchSuggestions } = 
    useFetchSearch ? 
      useTagsFieldWithFetchSearch({ 
        defaultValue, 
        useFetchSearch 
      }) :
      useTagsFieldWithAlgoliaSearch({ 
        defaultValue, 
        useFetchSearch 
      });
  const syncSelections = (selections = []) => {
    const selectionsString = selections
      .map((selection) => selection.name)
      .join(', ');
    onInput(selectionsString);
  };
  return {
    defaultSelections,
    /**
    * Fetches tags for a given search term
    *
    * @param {string} searchTerm The text to search for
    * @returns {Promise} Promise which resolves to the tag search results
    */
    fetchSuggestions,
    /**
    * Converts the array of selected items into a plain string,
    * and ensures the `onInput` callback is triggered with the new tags list
    * @param {Array} selections
    */
    syncSelections,
  };
};

const useTagsFieldWithFetchSearch = ({ useFetchSearch }) => {
  const { defaultSelections } = __useTagsField({
    useFetchSearch,
    searchTags__: (someTagName) => 
      fetchSearch('tags', { name: someTagName }).then(({ result = [] }) => {
        const [potentialMatch = {}] = result;
        return potentialMatch.name === someTagName
          ? potentialMatch
          : { name: someTagName };
      })
  });
  const fetchSuggestions = (searchTerm) => (
    fetchSearch('tags', { name: searchTerm }).then(
      (response) => response.result
    )
  );
  return {
    defaultSelections,
    fetchSuggestions
  };
};

const useTagsFieldWithAlgoliaSearch = ({ useFetchSearch }) => {
  const env = document.querySelector('meta[name="environment"]')?.content;
  const {algoliaId, algoliaSearchKey} = document.body.dataset;
  const algoliaClient = algoliasearch(algoliaId, algoliaSearchKey);
  const algoliaIndex = algoliaClient.initIndex(`Tag_${env}`);
  const { defaultSelections } = __useTagsField({
    useFetchSearch,
    searchTags__: (someTagName) =>
      algoliaIndex.search(someTagName).then(({ hits }) => {
        const [potentialMatch = {}] = hits;
        return potentialMatch.name === someTagName
          ? potentialMatch
          : { name: someTagName };
      })
  });
  const subforemId = document.body.dataset.subforemId;
  const fetchSuggestions = (searchTerm) => (
    algoliaIndex.search(searchTerm, {
      facetFilters: subforemId ? [`subforem_ids:${subforemId}`] : ['supported:true'],
    }).then(
      (response) => response.hits
    )
  );
  return {
    defaultSelections,
    fetchSuggestions
  };
};

const __useTagsField = ({ useFetchSearch, searchTags__ }) => {
  const [defaultSelections, setDefaultSelections] = useState([]);
  const [defaultsLoaded, setDefaultsLoaded] = useState(false);
  useEffect(() => {
    // Previously selected tags are passed as a plain comma separated string
    // Fetching further tag data allows us to display a richer UI
    // This fetch only happens once on first component load
    if (defaultValue && defaultValue !== '' && !defaultsLoaded) {
      const tagNames = defaultValue.split(', ');
      const tagRequests = tagNames.map((someTagName) => searchTags__(someTagName));
      Promise.all(tagRequests).then((data) => {
        setDefaultSelections(data);
      });
    }
    setDefaultsLoaded(true);
  }, [defaultValue, defaultsLoaded, useFetchSearch]);
  return {
    defaultSelections
  };
};