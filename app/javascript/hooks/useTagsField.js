import { useEffect, useState } from 'react';
import { fetchSearch } from '@utilities/search';

export const useTagsField = ({ defaultValue, onInput }) => {
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

  /**
   * Converts the array of selected items into a plain string
   * @param {Array} selections
   */
  const syncSelections = (selections = []) => {
    const selectionsString = selections
      .map((selection) => selection.name)
      .join(', ');
    onInput(selectionsString);
  };

  /**
   *
   * @param {*} searchTerm
   * @returns
   */
  const fetchSuggestions = (searchTerm) =>
    fetchSearch('tags', { name: searchTerm }).then(
      (response) => response.result,
    );

  return {
    defaultSelections,
    topTags,
    fetchSuggestions,
    syncSelections,
  };
};
