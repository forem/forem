// Shared behavior between the reading list and history pages
import { fetchSearch } from '../utilities/search';

// Provides the initial state for the component
export function defaultState(options) {
  const state = {
    query: '',
    index: null,

    page: 0,
    hitsPerPage: 80,

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
  component.search(query, {
    tags: selectedTags,
    statusView,
    appendItems: false,
  });
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
  component.search(query, { tags: newTags, statusView, appendItems: false });
}

export function clearSelectedTags(event) {
  event.preventDefault();

  const component = this;
  const { query, statusView } = component.state;
  const newTags = [];
  component.setState({ selectedTags: newTags, page: 0, items: [] });
  component.search(query, { tags: newTags, statusView, appendItems: false });
}

// Perform the initial search
export function performInitialSearch({ searchOptions = {} }) {
  const component = this;
  const { hitsPerPage } = component.state;
  const dataHash = { page: 0, per_page: hitsPerPage };

  if (searchOptions.status) {
    dataHash.status = searchOptions.status.split(',');
  }

  const responsePromise = fetchSearch('reactions', dataHash);
  return responsePromise.then((response) => {
    const reactions = response.result;
    const availableTags = [
      ...new Set(reactions.flatMap((rxn) => rxn.reactable.tag_list)),
    ].sort();
    component.setState({
      page: 0,
      items: reactions,
      itemsLoaded: true,
      showLoadMoreButton: hitsPerPage < response.total,
      availableTags,
    });
  });
}

// Main search function
export function search(query, { page, tags, statusView, appendItems = false }) {
  const component = this;

  // allow the page number to come from the calling function
  // we check `undefined` because page can be 0
  const newPage = page === undefined ? component.state.page : page;

  const { hitsPerPage, items: existingItems } = component.state;

  const dataHash = {
    search_fields: query,
    page: newPage,
    per_page: hitsPerPage,
  };

  if (tags && tags.length > 0) {
    dataHash.tag_names = tags;
    dataHash.tag_boolean_mode = 'all';
  }

  if (statusView) {
    dataHash.status = statusView.split(',');
  }

  const responsePromise = fetchSearch('reactions', dataHash);
  return responsePromise.then((response) => {
    const reactions = response.result;

    let items;
    if (appendItems) {
      // we append the new reactions at the bottom of the list, for pagination
      items = [...existingItems, ...reactions];
    } else {
      items = reactions;
    }

    component.setState({
      query,
      page: newPage,
      items,
      showLoadMoreButton: items.length < response.total,
    });
  });
}

// Retrieve the results in the next page
export function loadNextPage() {
  const component = this;

  const { query, selectedTags, page, statusView } = component.state;
  component.setState({ page: page + 1 });
  component.search(query, {
    page: page + 1,
    tags: selectedTags,
    statusView,
    appendItems: true,
  });
}
