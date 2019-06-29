// Shared behavior between the reading list and history pages
import setupAlgoliaIndex from '../src/utils/algolia';

// Provides the initial state for the component
export function defaultState(options) {
  const state = {
    query: '',
    index: null,

    page: 0,
    hitsPerPage: 100,
    totalCount: 0,

    items: [],
    itemsLoaded: false,

    availableTags: [],
    selectedTags: [],

    showLoadMoreButton: false,
  };
  return Object.assign({}, state, options);
}

// Starts the search when the user types in the search box
export function onSearchBoxTyping(event) {
  const component = this;

  const query = event.target.value;
  const { selectedTags, statusView } = component.state;

  component.setState({ page: 0, items: [] });
  component.search(query, { tags: selectedTags, statusView });
}

// Perform the initial search (using Algolia)
export function performInitialSearch({
  containerId,
  indexName,
  searchOptions = {},
}) {
  const component = this;
  const { hitsPerPage } = component.state;

  const index = setupAlgoliaIndex({ containerId, indexName });

  index.search('', searchOptions).then(result => {
    component.setState({
      items: result.hits,
      totalCount: result.nbHits,
      index, // set the index in the component state, to be retrieved later
      itemsLoaded: true,
      showLoadMoreButton: result.hits.length === hitsPerPage,
    });
  });
}

// Main search function (using Algolia)
export function search(query, { tags, statusView }) {
  const component = this;

  const { index, hitsPerPage, page, items } = component.state;

  const filters = { hitsPerPage, page };
  if (tags && tags.length > 0) {
    filters.tagFilters = tags;
  }

  if (statusView) {
    filters.filters = `status:${statusView}`;
  }

  index.search(query, filters).then(result => {
    // append new items at the end
    const allItems = [...items, ...result.hits];

    component.setState({
      query,
      items: allItems,
      totalCount: result.nbHits,
      showLoadMoreButton: result.hits.length === hitsPerPage,
    });
  });
}
