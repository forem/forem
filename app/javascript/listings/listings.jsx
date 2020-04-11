import { h, Component } from 'preact';
import debounceAction from '../src/utils/debounceAction';
import { fetchSearch } from '../src/utils/search';
import ClearQueryButton from './elements/clearQueryButton';
import ModalBackground from './elements/modalBackground';
import Modal from './elements/modal';
import AllListings from './elements/allListings';
import SelectedTags from './elements/selectedTags';
import NextPageButton from './elements/nextPageButton';
import ClassifiedFiltersCategories from './elements/classifiedFiltersCategories';
import {
  LISTING_PAGE_SIZE,
  updateListings,
  getQueryParams,
  resizeAllMasonryItems,
} from './utils';

export class Listings extends Component {
  state = {
    listings: [],
    query: '',
    tags: [],
    category: '',
    allCategories: [],
    initialFetch: true,
    currentUserId: null,
    openedListing: null,
    message: '',
    slug: null,
    page: 0,
    showNextPageButton: false,
  };

  componentWillMount() {
    const params = getQueryParams();
    const container = document.getElementById('classifieds-index-container');
    const category = container.dataset.category || '';
    const allCategories = JSON.parse(container.dataset.allcategories || []);
    let tags = [];
    let openedListing = null;
    let slug = null;
    let listings = [];

    if (params.t) {
      tags = params.t.split(',');
    }

    const query = params.q || '';

    if (tags.length === 0 && query === '') {
      listings = JSON.parse(container.dataset.listings);
    }

    if (container.dataset.displayedlisting) {
      openedListing = JSON.parse(container.dataset.displayedlisting);
      ({ slug } = openedListing);
      document.body.classList.add('modal-open');
    }

    this.debouncedClassifiedListingSearch = debounceAction(
      this.handleQuery.bind(this),
      { time: 150, config: { leading: true } },
    );

    this.setState({
      query,
      tags,
      category,
      allCategories,
      listings,
      openedListing,
      slug,
    });
    this.listingSearch(query, tags, category, slug);
    this.setUser();

    document.body.addEventListener('keydown', this.handleKeyDown);

    /*
      The width of the columns also changes when the browser is resized
      so we will also call this function on window resize to recalculate
      each grid item's height to avoid content overflow
    */
    window.addEventListener('resize', resizeAllMasonryItems);
  }

  componentDidUpdate() {
    this.triggerMasonry();
  }

  componentWillUnmount() {
    document.body.removeEventListener('keydown', this.handleKeyDown);
  }

  addTag = (e, tag) => {
    e.preventDefault();
    const { query, tags, category } = this.state;
    const newTags = tags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag);
    }
    this.setState({ tags: newTags, page: 0 });
    this.listingSearch(query, newTags, category, null);
    window.scroll(0, 0);
  };

  removeTag = (e, tag) => {
    e.preventDefault();
    const { query, tags, category } = this.state;
    const newTags = tags;
    const index = newTags.indexOf(tag);
    if (newTags.indexOf(tag) > -1) {
      newTags.splice(index, 1);
    }
    this.setState({ tags: newTags, page: 0 });
    this.listingSearch(query, newTags, category, null);
  };

  handleKeyPressedOnSelectedTags = (e, tag) => {
    if (e.key === 'Enter') {
      this.removeTag(e, tag);
    }
  };

  selectCategory = (e, cat) => {
    e.preventDefault();
    const { query, tags } = this.state;
    this.setState({ category: cat, page: 0 });
    this.listingSearch(query, tags, cat, null);
  };

  handleKeyDown = (e) => {
    // Enable Escape key to close an open listing.
    this.handleCloseModal(e);
  };

  handleCloseModal = (e) => {
    const { openedListing } = this.state;
    if (
      (openedListing !== null && e.key === 'Escape') ||
      e.target.id === 'single-classified-listing-container__inner' ||
      e.target.id === 'classified-filters' ||
      e.target.id === 'classified-listings-modal-background'
    ) {
      const { query, tags, category } = this.state;
      this.setState({ openedListing: null, page: 0 });
      this.setLocation(query, tags, category, null);
      document.body.classList.remove('modal-open');
    }
  };

  handleOpenModal = (e, listing) => {
    e.preventDefault();
    this.setState({ openedListing: listing });
    window.history.replaceState(
      null,
      null,
      `/listings/${listing.category}/${listing.slug}`,
    );
    this.setLocation(null, null, listing.category, listing.slug);
    document.body.classList.add('modal-open');
  };

  handleDraftingMessage = (e) => {
    e.preventDefault();
    this.setState({ message: e.target.value });
  };

  handleSubmitMessage = (e) => {
    e.preventDefault();
    const { message, openedListing } = this.state;
    if (message.replace(/\s/g, '').length === 0) {
      return;
    }
    const formData = new FormData();
    formData.append('user_id', openedListing.user_id);
    formData.append('message', `**re: ${openedListing.title}** ${message}`);
    formData.append('controller', 'chat_channels');

    const destination = `/connect/@${openedListing.author.username}`;
    const metaTag = document.querySelector("meta[name='csrf-token']");
    window
      .fetch('/chat_channels/create_chat', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': metaTag.getAttribute('content'),
        },
        body: formData,
        credentials: 'same-origin',
      })
      .then(() => {
        window.location.href = destination;
      });
  };

  handleQuery = (e) => {
    const { tags, category } = this.state;
    this.setState({ query: e.target.value, page: 0 });
    this.listingSearch(e.target.value, tags, category, null);
  };

  clearQuery = () => {
    const { tags, category } = this.state;
    document.getElementById('listings-search').value = '';
    this.setState({ query: '', page: 0 });
    this.listingSearch('', tags, category, null);
  };

  loadNextPage = () => {
    const { query, tags, category, slug, page } = this.state;
    this.setState({ page: page + 1 });
    this.listingSearch(query, tags, category, slug);
  };

  setUser = () => {
    const { currentUserId } = this.state;
    setTimeout(() => {
      if (window.currentUser && currentUserId === null) {
        this.setState({ currentUserId: window.currentUser.id });
      }
    }, 300);
    setTimeout(() => {
      if (window.currentUser && currentUserId === null) {
        this.setState({ currentUserId: window.currentUser.id });
      }
    }, 1000);
  };

  triggerMasonry = () => {
    resizeAllMasonryItems();
    setTimeout(resizeAllMasonryItems, 1);
    setTimeout(resizeAllMasonryItems, 3);
  };

  setLocation = (query, tags, category, slug) => {
    let newLocation = '';
    if (slug) {
      newLocation = `/listings/${category}/${slug}`;
    } else if (query.length > 0 && tags.length > 0) {
      newLocation = `/listings/${category}?q=${query}&t=${tags}`;
    } else if (query.length > 0) {
      newLocation = `/listings/${category}?q=${query}`;
    } else if (tags.length > 0) {
      newLocation = `/listings/${category}?t=${tags}`;
    } else if (category.length > 0) {
      newLocation = `/listings/${category}`;
    } else {
      newLocation = '/listings';
    }
    window.history.replaceState(null, null, newLocation);
  };

  /**
   * Call search API for ClassifiedListings
   *
   * @param {string} query - The search term
   * @param {string} tags - The tags selected by the user
   * @param {string} category - The category selected by the user
   * @param {string} slug - The listing's slug
   *
   * @returns {Promise} A promise object with response formatted as JSON.
   */
  listingSearch(query, tags, category, slug) {
    const { page } = this.state;
    const dataHash = {
      category,
      classified_listing_search: query,
      page,
      per_page: LISTING_PAGE_SIZE,
      tags,
    };

    const responsePromise = fetchSearch('classified_listings', dataHash);
    return responsePromise.then((response) => {
      const classifiedListings = response.result;
      const fullListings = updateListings(classifiedListings);
      this.setState({
        listings: fullListings,
        initialFetch: false,
        showNextPageButton: classifiedListings.length === LISTING_PAGE_SIZE,
      });
      this.setLocation(query, tags, category, slug);
    });
  }

  render() {
    const {
      listings,
      query,
      tags,
      category,
      allCategories,
      currentUserId,
      openedListing,
      showNextPageButton,
      initialFetch,
      message,
    } = this.state;

    const shouldRenderModal = openedListing != null && undefined;
    const shouldRenderClearQueryButton = query.length > 0;

    if (initialFetch) {
      this.triggerMasonry();
    }
    return (
      <div className="listings__container">
        {shouldRenderModal && (
          <ModalBackground onClick={this.handleCloseModal} />
        )}
        <div className="classified-filters" id="classified-filters">
          <ClassifiedFiltersCategories
            categories={allCategories}
            category={category}
            onClick={this.selectCategory}
          />
          <div className="classified-filters-tags" id="classified-filters-tags">
            <input
              type="text"
              placeholder="search"
              id="listings-search"
              autoComplete="off"
              defaultValue={message}
              onKeyUp={this.debouncedClassifiedListingSearch}
            />
            {shouldRenderClearQueryButton && (
              <ClearQueryButton onClick={this.clearQuery} />
            )}
            <SelectedTags
              tags={tags}
              onClick={this.removeTag}
              onKeyPress={this.handleKeyPressedOnSelectedTags}
            />
          </div>
        </div>
        <AllListings
          listings={listings}
          onAddTag={this.addTag}
          onChangeCategory={this.selectCategory}
          currentUserId={currentUserId}
          onOpenModal={this.handleOpenModal}
        />
        {showNextPageButton && <NextPageButton onClick={this.loadNextPage} />}
        {shouldRenderModal && (
          <Modal
            currentUserId={currentUserId}
            onAddTag={this.addTag}
            onChange={this.handleDraftingMessage}
            onClick={this.handleCloseModal}
            onChangeCategory={this.selectCategory}
            onOpenModal={this.handleOpenModal}
            onSubmit={this.handleSubmitMessage}
            listing={openedListing}
            message={message}
          />
        )}
      </div>
    );
  }
}

Listings.displayName = 'Classified Listings';
