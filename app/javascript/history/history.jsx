import { h, Component } from 'preact';
import { PropTypes } from 'preact-compat';
import debounce from 'lodash.debounce';

import {
  defaultState,
  loadNextPage,
  onSearchBoxType,
  performInitialSearch,
  search,
  toggleTag,
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
    this.onSearchBoxType = debounce(onSearchBoxType.bind(this), 300, {
      leading: true,
    });
    this.loadNextPage = loadNextPage.bind(this);
    this.performInitialSearch = performInitialSearch.bind(this);
    this.search = search.bind(this);
    this.toggleTag = toggleTag.bind(this);
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
