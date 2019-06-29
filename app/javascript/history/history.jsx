import { h, Component } from 'preact';
import { PropTypes } from 'preact-compat';
import debounce from 'lodash.debounce';

import {
  defaultState,
  performInitialSearch,
  search,
  onSearchBoxTyping,
} from '../searchableItemList/searchableItemList';
import { ItemListLoadMoreButton } from '../src/components/ItemList/ItemListLoadMoreButton';
import { ItemListTags } from '../src/components/ItemList/ItemListTags';
import { ItemListItem } from '../src/components/ItemList/ItemListItem';

export class History extends Component {
  constructor(props) {
    super(props);

    const { availableTags } = this.props;
    this.state = defaultState({ availableTags });

    // bind and initialize all shared functions
    this.onSearchBoxTyping = debounce(onSearchBoxTyping.bind(this), 300, {
      leading: true,
    });
    this.performInitialSearch = performInitialSearch.bind(this);
    this.search = search.bind(this);
  }

  componentDidMount() {
    const { hitsPerPage } = this.state;

    this.performInitialSearch({
      containerId: 'history',
      indexName: 'UserHistory',
      searchOptions: {
        hitsPerPage,
      },
    });
  }

  toggleTag = (event, tag) => {
    event.preventDefault();

    const { query, selectedTags } = this.state;
    const newTags = selectedTags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag);
    } else {
      newTags.splice(newTags.indexOf(tag), 1);
    }

    this.setState({ selectedTags: newTags, page: 0, items: [] });
    this.search(query, { tags: newTags });
  };

  loadNextPage = () => {
    const { query, selectedTags, page } = this.state;
    this.setState({ page: page + 1 });
    this.search(query, { selectedTags });
  };

  renderEmptyItems() {
    const { selectedTags, query } = this.state;

    return (
      <div>
        <div className="items-empty">
          <h1>
            {selectedTags.length === 0 && query.length === 0
              ? 'Your History is Lonely'
              : 'Nothing with this filter 🤔'}
          </h1>
        </div>
      </div>
    );
  }

  render() {
    const {
      items,
      itemsLoaded,
      totalCount,
      availableTags,
      selectedTags,
      showLoadMoreButton,
    } = this.state;

    const itemsToRender = items.map(item => <ItemListItem item={item} />);

    return (
      <div className="home item-list">
        <div className="side-bar">
          <div className="widget filters">
            <input
              onKeyUp={this.onSearchBoxTyping}
              placeHolder="search your history"
            />

            <ItemListTags
              availableTags={availableTags}
              selectedTags={selectedTags}
              onClick={this.toggleTag}
            />
          </div>
        </div>

        <div className="items-container">
          <div className={`results ${itemsLoaded ? 'results--loaded' : ''}`}>
            <div className="results-header">
              History
              {` (${totalCount > 0 ? totalCount : 'empty'})`}
            </div>
            {items.length > 0 ? itemsToRender : this.renderEmptyItems()}
          </div>

          <ItemListLoadMoreButton
            show={showLoadMoreButton}
            onClick={this.loadNextPage}
          />
        </div>
      </div>
    );
  }
}

History.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
};
