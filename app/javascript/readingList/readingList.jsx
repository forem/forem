import { h, Component, Fragment } from 'preact';
import PropTypes from 'prop-types';

import {
  loadNextPage,
  onSearchBoxType,
  performInitialSearch,
  search,
  selectTag,
  clearSelectedTags,
} from '../searchableItemList/searchableItemList';
import { ItemListItem } from './components/ItemListItem';
import { ItemListItemArchiveButton } from './components/ItemListItemArchiveButton';
import { TagList } from './components/TagList';
import { MediaQuery } from '@components/MediaQuery';
import { BREAKPOINTS } from '@components/useMediaQuery';
import { debounceAction } from '@utilities/debounceAction';
import { Button } from '@crayons';
import { request } from '@utilities/http';
import { i18next } from '@utilities/locale';

const NO_RESULTS_WITH_FILTER_MESSAGE = i18next.t('readingList.nothing');
const STATUS_VIEW_VALID = 'valid,confirmed';
const STATUS_VIEW_ARCHIVED = 'archived';
const READING_LIST_ARCHIVE_PATH = '/readinglist/archive';
const READING_LIST_PATH = '/readinglist';

function ItemList({ items, archiveButtonLabel, toggleArchiveStatus }) {
  return items.map((item) => {
    return (
      <ItemListItem item={item} key={item.id}>
        <ItemListItemArchiveButton
          text={archiveButtonLabel}
          onClick={(e) => toggleArchiveStatus(e, item)}
        />
      </ItemListItem>
    );
  });
}

export class ReadingList extends Component {
  constructor(props) {
    super(props);

    const { statusView } = this.props;

    this.state = {
      archiving: false,
      query: '',
      index: null,
      page: 0,
      hitsPerPage: 80,
      items: [],
      itemsLoaded: false,
      itemsTotal: 0,
      availableTags: [],
      selectedTag: '',
      showLoadMoreButton: false,
      statusView,
    };

    // bind and initialize all shared functions
    this.onSearchBoxType = debounceAction(onSearchBoxType.bind(this), {
      leading: true,
    });
    this.loadNextPage = loadNextPage.bind(this);
    this.performInitialSearch = performInitialSearch.bind(this);
    this.search = search.bind(this);
    this.selectTag = selectTag.bind(this);
    this.clearSelectedTags = clearSelectedTags.bind(this);
  }

  componentDidMount() {
    const { statusView } = this.state;

    this.performInitialSearch({
      searchOptions: { status: `${statusView}` },
    });
  }

  toggleStatusView = (event) => {
    event.preventDefault();

    const { query, selectedTag } = this.state;

    const isStatusViewValid = this.statusViewValid();
    const newStatusView = isStatusViewValid
      ? STATUS_VIEW_ARCHIVED
      : STATUS_VIEW_VALID;
    const newPath = isStatusViewValid
      ? READING_LIST_ARCHIVE_PATH
      : READING_LIST_PATH;

    // empty items so that changing the view will start from scratch
    this.setState({ statusView: newStatusView, items: [], selectedTag });

    this.search(query, {
      page: 0,
      tags: selectedTag ? [selectedTag] : [],
      statusView: newStatusView,
    });

    // change path in the address bar
    window.history.replaceState(null, null, newPath);
  };

  toggleArchiveStatus = (event, item) => {
    event.preventDefault();

    const { statusView, items, itemsTotal } = this.state;
    request(`/reading_list_items/${item.id}`, {
      method: 'PUT',
      body: { current_status: statusView },
    });

    const newItems = items;
    newItems.splice(newItems.indexOf(item), 1);
    this.setState({
      archiving: true,
      items: newItems,
      itemsTotal: itemsTotal - 1,
    });

    // hide the snackbar in a few moments
    setTimeout(() => {
      this.setState({ archiving: false });
    }, 1000);
  };

  statusViewValid() {
    const { statusView } = this.state;
    return statusView === STATUS_VIEW_VALID;
  }

  renderEmptyItems() {
    const { itemsLoaded, selectedTag = '', query } = this.state;
    const showMessage = selectedTag.length === 0 && query.length === 0;

    if (itemsLoaded && this.statusViewValid()) {
      return (
        <section className="align-center p-9 py-10 color-base-80">
          <h2 className="fw-bold fs-l">
            {showMessage
              ? i18next.t('readingList.empty')
              : NO_RESULTS_WITH_FILTER_MESSAGE}
          </h2>
          <p
            class="color-base-60 pt-2" /* TODO yheuhtozr: i18n interpolation */
          >
            {i18next.t('readingList.click1')}
            <span class="fw-bold">
              {i18next.t('readingList.click2')}
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                className="crayons-icon mx-1"
                xmlns="http://www.w3.org/2000/svg"
                role="img"
              >
                <path d="M5 2h14a1 1 0 011 1v19.143a.5.5 0 01-.766.424L12 18.03l-7.234 4.536A.5.5 0 014 22.143V3a1 1 0 011-1zm13 2H6v15.432l6-3.761 6 3.761V4z" />
              </svg>
            </span>
            {i18next.t('readingList.click3')}
          </p>
        </section>
      );
    }

    return (
      <h2 className="align-center p-9 py-10 color-base-80 fw-bold fs-l">
        {showMessage
          ? i18next.t('readingList.empty_archive')
          : NO_RESULTS_WITH_FILTER_MESSAGE}
      </h2>
    );
  }

  render() {
    const {
      items = [],
      itemsTotal,
      availableTags,
      selectedTag = '',
      showLoadMoreButton,
      archiving,
      loading = false,
    } = this.state;

    const isStatusViewValid = this.statusViewValid();
    const archiveButtonLabel = i18next.t(
      `readingList.${isStatusViewValid ? 'to_archive' : 'to_unarchive'}`,
    );

    const snackBar = archiving ? (
      <div className="snackbar">
        {i18next.t(
          `readingList.${isStatusViewValid ? 'archiving' : 'unarchiving'}`,
        )}
      </div>
    ) : (
      ''
    );
    return (
      <main id="main-content">
        <header className="crayons-layout l:grid-cols-2 pb-0">
          <h1 class="crayons-title">
            {i18next.t(
              `readingList.${isStatusViewValid ? 'heading' : 'archive'}`,
            )}
            {i18next.t('readingList.total', { total: itemsTotal })}
          </h1>
          <fieldset className="grid gap-2 m:flex m:justify-end m:items-center l:mb-0 mb-2 px-2 m:px-0">
            <legend className="hidden">
              {i18next.t('readingList.filter')}
            </legend>
            <Button
              onClick={(e) => this.toggleStatusView(e)}
              className="whitespace-nowrap l:mr-2"
              variant="outlined"
              url={READING_LIST_ARCHIVE_PATH}
              tagName="a"
              data-no-instant
            >
              {i18next.t(
                `readingList.${
                  isStatusViewValid ? 'view_archive' : 'view_list'
                }`,
              )}
            </Button>
            <input
              aria-label={i18next.t('readingList.aria_label')}
              onKeyUp={this.onSearchBoxType}
              placeholder={i18next.t('readingList.placeholder')}
              className="crayons-textfield"
            />
            <MediaQuery
              query={`(max-width: ${BREAKPOINTS.Medium - 1}px)`}
              render={(matches) => {
                return (
                  matches && (
                    <TagList
                      availableTags={availableTags}
                      selectedTag={selectedTag}
                      onSelectTag={this.selectTag}
                      isMobile={true}
                    />
                  )
                );
              }}
            />
          </fieldset>
        </header>
        <MediaQuery
          query={`(min-width: ${BREAKPOINTS.Medium}px)`}
          render={(matches) => {
            return (
              <div className="crayons-layout crayons-layout--2-cols">
                {matches && (
                  <div className="crayons-layout__sidebar-left">
                    <TagList
                      availableTags={availableTags}
                      selectedTag={selectedTag}
                      onSelectTag={this.selectTag}
                    />
                  </div>
                )}
                <section className="crayons-layout__content crayons-card mb-4">
                  {items.length > 0 ? (
                    <Fragment>
                      <ItemList
                        items={items}
                        archiveButtonLabel={archiveButtonLabel}
                        toggleArchiveStatus={this.toggleArchiveStatus}
                      />
                      {showLoadMoreButton && (
                        <div className="flex justify-center my-2">
                          <Button
                            onClick={this.loadNextPage}
                            variant="secondary"
                            className="w-max"
                          >
                            {i18next.t('readingList.more')}
                          </Button>
                        </div>
                      )}
                    </Fragment>
                  ) : loading ? null : (
                    this.renderEmptyItems()
                  )}
                </section>
              </div>
            );
          }}
        />
        {snackBar}
      </main>
    );
  }
}

ReadingList.defaultProps = {
  statusView: STATUS_VIEW_VALID,
};

ReadingList.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  statusView: PropTypes.oneOf([STATUS_VIEW_VALID, STATUS_VIEW_ARCHIVED]),
};
