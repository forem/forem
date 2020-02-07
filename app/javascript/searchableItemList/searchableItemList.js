// Shared behavior between the reading list and history pages
import setupAlgoliaIndex from '../src/utils/algolia';

// Provides the initial state for the component
export function defaultState(options) {
  const state = {
    query: '',
    index: null,

    page: 0,
    hitsPerPage: 80,
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
export function onSearchBoxType(event) {
  const component = this;

  const query = event.target.value;
  const { selectedTags, statusView } = component.state;

  component.setState({ page: 0 });
  component.search(query, { tags: selectedTags, statusView });
}

export function toggleTag(event, tag) {
  event.preventDefault();

  const component = this;
  const { query, selectedTags, statusView } = component.state;
  const newTags = selectedTags;
  if (newTags.indexOf(tag) === -1) {
    newTags.push(tag);
  } else {
    newTags.splice(newTags.indexOf(tag), 1);
  }
  component.setState({ selectedTags: newTags, page: 0, items: [] });
  component.search(query, { tags: newTags, statusView });
}

export function clearSelectedTags(event) {
  event.preventDefault();

  const component = this;
  const { query, statusView } = component.state;
  const newTags = [];
  component.setState({ selectedTags: newTags, page: 0, items: [] });
  component.search(query, { tags: newTags, statusView });
}

// Perform the initial search
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
      // show the button if the number of total results is greater
      // than the number of results for the current page
      showLoadMoreButton: result.nbHits > hitsPerPage,
    });
  });
}

// Main search function
export function search(query, { page, tags, statusView }) {
  const component = this;

  // allow the page number to come from the calling function
  // we check `undefined` because page can be 0
  const newPage = page === undefined ? component.state.page : page;

  const { index, hitsPerPage, items } = component.state;

  const filters = { hitsPerPage, page: newPage };
  if (tags && tags.length > 0) {
    filters.tagFilters = tags;
  }

  if (statusView) {
    filters.filters = `status:${statusView}`;
  }
  index.search(query, filters).then(result => {
    // append new items at the end
    const allItems =
      page === undefined ? result.hits : [...items, ...result.hits];
    component.setState({
      query,
      page: newPage,
      items: result.hits,
      totalCount: allItems.length,
      // show the button if the number of items is lower than the number
      // of available results
      showLoadMoreButton: allItems.length < result.nbHits,
    });
  });
}

// Retrieve the results in the next page
export function loadNextPage() {
  const component = this;

  const { query, selectedTags, page, statusView } = component.state;
  component.setState({ page: page + 1 });
  component.search(query, { tags: selectedTags, statusView });
}
