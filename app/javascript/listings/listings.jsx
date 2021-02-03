import { h, Component, Fragment } from 'preact';
import { debounceAction } from '../utilities/debounceAction';
import { fetchSearch } from '../utilities/search';
import { KeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { ModalBackground } from './components/ModalBackground';
import { Modal } from './components/Modal';
import { AllListings } from './components/AllListings';
import { ListingFilters } from './components/ListingFilters';
import {
  LISTING_PAGE_SIZE,
  MATCH_LISTING,
  updateListings,
  getQueryParams,
  resizeAllMasonryItems,
  getLocation,
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
    const container = document.getElementById('listings-index-container');
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

    this.debouncedListingSearch = debounceAction(this.handleQuery.bind(this), {
      time: 150,
      config: { leading: true },
    });

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

  addTag = (e, tag) => {
    e.preventDefault();
    if (document.body.classList.contains('modal-open')) {
      this.handleCloseModal('close-modal');
    }
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

  selectCategory = (e, cat = '') => {
    e.preventDefault();
    const { query, tags } = this.state;
    this.setState({ category: cat, page: 0 });
    this.listingSearch(query, tags, cat, null);
  };

  handleCloseModal = (e) => {
    const { openedListing } = this.state;
    if (
      e === 'close-modal' ||
      (openedListing !== null && e.key === 'Escape') ||
      MATCH_LISTING.includes(e.target.id)
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

    const destination = `/connect/@${openedListing.user.username}`;
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
    }, 1000);
  };

  triggerMasonry = () => {
    resizeAllMasonryItems();
    setTimeout(resizeAllMasonryItems, 1);
    setTimeout(resizeAllMasonryItems, 3);
  };

  setLocation = (query, tags, category, slug) => {
    const newLocation = getLocation({ query, tags, category, slug });
    window.history.replaceState(null, null, newLocation);
  };

  /**
   * Call search API for Listings
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
      listing_search: query,
      page,
      per_page: LISTING_PAGE_SIZE,
      tags,
      tag_boolean_mode: 'all',
    };

    const responsePromise = fetchSearch('listings', dataHash);
    return responsePromise.then((response) => {
      const listings = response.result;
      const fullListings = updateListings(listings);
      this.setState({
        listings: fullListings,
        initialFetch: false,
        showNextPageButton: listings.length === LISTING_PAGE_SIZE,
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

    const shouldRenderModal =
      openedListing !== null && openedListing !== undefined;

    if (initialFetch) {
      this.triggerMasonry();
    }
    return (
      <div className="crayons-layout crayons-layout--2-cols">
        <ListingFilters
          categories={allCategories}
          category={category}
          onSelectCategory={this.selectCategory}
          message={message}
          onKeyUp={this.debouncedListingSearch}
          onClearQuery={this.clearQuery}
          onRemoveTag={this.removeTag}
          tags={tags}
          onKeyPress={this.handleKeyPressedOnSelectedTags}
          query={query}
        />
        <AllListings
          listings={listings}
          onAddTag={this.addTag}
          onChangeCategory={this.selectCategory}
          currentUserId={currentUserId}
          onOpenModal={this.handleOpenModal}
          showNextPageButton={showNextPageButton}
          loadNextPage={this.loadNextPage}
        />
        {shouldRenderModal && (
          <Fragment>
            <div className="crayons-modal">
              <Modal
                currentUserId={currentUserId}
                onAddTag={this.addTag}
                onChangeDraftingMessage={this.handleDraftingMessage}
                onClick={this.handleCloseModal}
                onChangeCategory={this.selectCategory}
                onOpenModal={this.handleOpenModal}
                onSubmit={this.handleSubmitMessage}
                listing={openedListing}
                message={message}
              />
              <ModalBackground onClick={this.handleCloseModal} />
            </div>
            <KeyboardShortcuts
              shortcuts={{
                Escape: this.handleCloseModal,
              }}
            />
          </Fragment>
        )}
      </div>
    );
  }
}

Listings.displayName = 'Classified Listings';
