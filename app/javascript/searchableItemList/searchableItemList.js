// Shared behavior between the reading list and history pages
import { fetchSearch } from '../utilities/search';

// Starts the search when the user types in the search box
export function onSearchBoxType(event) {
  const component = this;

  const query = event.target.value;
  const { selectedTag, statusView } = component.state;

  component.setState({ page: 0 });
  component.search(query, {
    tags: selectedTag ? [selectedTag] : [],
    statusView,
    appendItems: false,
  });
}

export function selectTag(event) {
  event.preventDefault();
  const { value, dataset } = event.target;
  const selectedTag = value ?? dataset.tag;
  const component = this;
  const { query, statusView } = component.state;

  component.setState({ selectedTag, page: 0, items: [] });
  component.search(query, {
    tags: selectedTag ? [selectedTag] : [],
    statusView,
    appendItems: false,
  });
}

export function clearSelectedTags(event) {
  event.preventDefault();

  const component = this;
  const { query, statusView } = component.state;
  component.setState({ selectedTag: '', page: 0, items: [] });
  component.search(query, { tags: [], statusView, appendItems: false });
}

// Perform the initial search
export function performInitialSearch({ searchOptions = {} }) {
  const component = this;
  const { hitsPerPage } = component.state;
  const dataHash = { page: 0, per_page: hitsPerPage };

  component.setState({ loading: true });

  if (searchOptions.status) {
    dataHash.status = searchOptions.status.split(',');
  }

  const responsePromise = fetchSearch('reactions', dataHash);
  return responsePromise.then((response) => {
    const reactions = response.result;
    // FIXME: [@rhymes] the list of tags in the left column of the reading list
    // is populated with only the tags belonging to items in the first page
    const availableTags = [
      ...new Set(reactions.flatMap((rxn) => rxn.reactable.tag_list)),
    ].sort();
    component.setState({
      page: 0,
      items: reactions,
      itemsLoaded: true,
      itemsTotal: response.total,
      showLoadMoreButton: hitsPerPage < response.total,
      availableTags,
      loading: false,
    });
  });
}

// Main search function
export function search(query, { page, tags, statusView, appendItems = false }) {
  const component = this;

  component.setState({ loading: true });

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
      itemsTotal: response.total,
      showLoadMoreButton: items.length < response.total,
      loading: false,
    });
  });
}

// Retrieve the results in the next page
export function loadNextPage() {
  const component = this;

  const { query, selectedTag, page, statusView } = component.state;
  component.setState({ page: page + 1 });
  component.search(query, {
    page: page + 1,
    tags: selectedTag ? [selectedTag] : [],
    statusView,
    appendItems: true,
  });
}
