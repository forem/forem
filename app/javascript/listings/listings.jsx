import { h, Component } from 'preact';
import debounceAction from '../src/utils/debounceAction';
import { fetchSearch } from '../src/utils/search';
import SingleListing from './singleListing';

/**
 * How many listings to show per page
 * @constant {number}
 */
const LISTING_PAGE_SIZE = 75;

function resizeMasonryItem(item) {
  /* Get the grid object, its row-gap, and the size of its implicit rows */
  const grid = document.getElementsByClassName('classifieds-columns')[0];
  const rowGap = parseInt(
    window.getComputedStyle(grid).getPropertyValue('grid-row-gap'),
    10,
  );
  const rowHeight = parseInt(
    window.getComputedStyle(grid).getPropertyValue('grid-auto-rows'),
    10,
  );

  const rowSpan = Math.ceil(
    (item.querySelector('.listing-content').getBoundingClientRect().height +
      rowGap) /
      (rowHeight + rowGap),
  );

  /* Set the spanning as calculated above (S) */
  // eslint-disable-next-line no-param-reassign
  item.style.gridRowEnd = `span ${rowSpan}`;
}

function resizeAllMasonryItems() {
  // Get all item class objects in one list
  const allItems = document.getElementsByClassName('single-classified-listing');

  /*
   * Loop through the above list and execute the spanning function to
   * each list-item (i.e. each masonry item)
   */
  // eslint-disable-next-line vars-on-top
  for (let i = 0; i < allItems.length; i += 1) {
    resizeMasonryItem(allItems[i]);
  }
}

function updateListings(classifiedListings) {
  const fullListings = [];

  classifiedListings.forEach(listing => {
    if (listing.bumped_at) {
      fullListings.push(listing);
    }
  });

  return fullListings;
}

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
    showNextPageButt: false,
  };

  componentWillMount() {
    const params = this.getQueryParams();
    const t = this;
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

    t.debouncedClassifiedListingSearch = debounceAction(
      this.handleQuery.bind(this),
      { time: 150, config: { leading: true } },
    );

    t.setState({
      query,
      tags,
      category,
      allCategories,
      listings,
      openedListing,
      slug,
    });
    t.listingSearch(query, tags, category, slug);
    t.setUser();

    document.body.addEventListener('keydown', t.handleKeyDown);

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

  selectCategory = (e, cat) => {
    e.preventDefault();
    const { query, tags } = this.state;
    this.setState({ category: cat, page: 0 });
    this.listingSearch(query, tags, cat, null);
  };

  handleKeyDown = e => {
    // Enable Escape key to close an open listing.
    this.handleCloseModal(e);
  };

  handleCloseModal = e => {
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

  handleDraftingMessage = e => {
    e.preventDefault();
    this.setState({ message: e.target.value });
  };

  handleSubmitMessage = e => {
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

  handleQuery = e => {
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

  getQueryParams = () => {
    let qs = document.location.search;
    qs = qs.split('+').join(' ');

    const params = {};
    let tokens;
    const re = /[?&]?([^=]+)=([^&]*)/g;

    // eslint-disable-next-line no-cond-assign
    while ((tokens = re.exec(qs))) {
      params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
    }

    return params;
  };

  loadNextPage = () => {
    const { query, tags, category, slug, page } = this.state;
    this.setState({ page: page + 1 });
    this.listingSearch(query, tags, category, slug);
  };

  setUser = () => {
    const t = this;
    setTimeout(() => {
      if (window.currentUser && t.state.currentUserId === null) {
        t.setState({ currentUserId: window.currentUser.id });
      }
    }, 300);
    setTimeout(() => {
      if (window.currentUser && t.state.currentUserId === null) {
        t.setState({ currentUserId: window.currentUser.id });
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
    const t = this;
    const { page } = t.state;
    const dataHash = {
      category,
      classified_listing_search: query,
      page,
      per_page: LISTING_PAGE_SIZE,
      tags,
    };

    const responsePromise = fetchSearch('classified_listings', dataHash);
    return responsePromise.then(response => {
      const classifiedListings = response.result;
      const fullListings = updateListings(classifiedListings);
      t.setState({
        listings: fullListings,
        initialFetch: false,
        showNextPageButt: classifiedListings.length === LISTING_PAGE_SIZE,
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
      showNextPageButt,
      initialFetch,
      message,
    } = this.state;
    const allListings = listings.map(listing => (
      <SingleListing
        onAddTag={this.addTag}
        onChangeCategory={this.selectCategory}
        listing={listing}
        currentUserId={currentUserId}
        onOpenModal={this.handleOpenModal}
        isOpen={false}
      />
    ));
    const selectedTags = tags.map(tag => (
      <span className="classified-tag">
        <a
          href="/listings?tags="
          className="tag-name"
          onClick={e => this.removeTag(e, tag)}
          data-no-instant
        >
          <span>{tag}</span>
          <span
            className="tag-close"
            onClick={e => this.removeTag(e, tag)}
            data-no-instant
            role="button"
            onKeyPress={e => e.key === 'Enter' && this.removeTag(e, tag)}
            tabIndex="0"
          >
            ×
          </span>
        </a>
      </span>
    ));
    const categoryLinks = allCategories.map(cat => (
      <a
        href={`/listings/${cat.slug}`}
        className={cat.slug === category ? 'selected' : ''}
        onClick={e => this.selectCategory(e, cat.slug)}
        data-no-instant
      >
        {cat.name}
      </a>
    ));
    let nextPageButt = '';
    if (showNextPageButt) {
      nextPageButt = (
        <div className="classifieds-load-more-button">
          <button onClick={e => this.loadNextPage(e)} type="button">
            Load More Listings
          </button>
        </div>
      );
    }
    const clearQueryButton =
      query.length > 0 ? (
        <button
          type="button"
          className="classified-search-clear"
          onClick={this.clearQuery}
        >
          ×
        </button>
      ) : (
        ''
      );
    let modal = '';
    let modalBg = '';
    let messageModal = '';
    if (openedListing) {
      modalBg = (
        <div
          className="classified-listings-modal-background"
          onClick={this.handleCloseModal}
          role="presentation"
          id="classified-listings-modal-background"
        />
      );
      if (openedListing.contact_via_connect) {
        messageModal = (
          <form
            id="listings-message-form"
            className="listings-contact-via-connect"
            onSubmit={this.handleSubmitMessage}
          >
            {openedListing.contact_via_connect &&
            openedListing.user_id !== currentUserId ? (
              <p>
                <b>
                  Contact
                  {` ${openedListing.author.name} `}
                  via DEV Connect
                </b>
              </p>
            ) : (
              <p>
                This is your active listing. Any member can contact you via this
                form.
              </p>
            )}
            <textarea
              value={message}
              onChange={this.handleDraftingMessage}
              id="new-message"
              rows="4"
              cols="70"
              placeholder="Enter your message here..."
            />
            <button type="submit" value="Submit" className="submit-button cta">
              SEND
            </button>
            <p>
              {openedListing.contact_via_connect &&
              openedListing.user_id !== currentUserId ? (
                <em>
                  Message must be relevant and on-topic with the listing. All
                  {' '}
                  private interactions 
                  {' '}
                  <b>must</b>
                  {' '}
                  abide by the
                  {' '}
                  <a href="/code-of-conduct">code of conduct</a>
                </em>
              ) : (
                <em>
                  All private interactions 
                  {' '}
                  <b>must</b>
                  {' '}
                  abide by the
                  {' '}
                  <a href="/code-of-conduct">code of conduct</a>
                </em>
              )}
            </p>
          </form>
        );
      }
      modal = (
        <div className="single-classified-listing-container">
          <div
            id="single-classified-listing-container__inner"
            className="single-classified-listing-container__inner"
            onClick={this.handleCloseModal}
            role="button"
            onKeyPress={this.handleCloseModal}
            tabIndex="0"
          >
            <SingleListing
              onAddTag={this.addTag}
              onChangeCategory={this.selectCategory}
              listing={openedListing}
              currentUserId={currentUserId}
              onOpenModal={this.handleOpenModal}
              isOpen
            />
            {messageModal}
            <a
              href="/about-listings"
              className="single-classified-listing-info-link"
            >
              About DEV Listings
            </a>
            <div className="single-classified-listing-container__spacer" />
          </div>
        </div>
      );
    }
    if (initialFetch) {
      this.triggerMasonry();
    }
    return (
      <div className="listings__container">
        {modalBg}
        <div className="classified-filters" id="classified-filters">
          <div className="classified-filters-categories">
            <a
              href="/listings"
              className={category === '' ? 'selected' : ''}
              onClick={e => this.selectCategory(e, '')}
              data-no-instant
            >
              all
            </a>
            {categoryLinks}
            <a href="/listings/new" className="classified-create-link">
              Create a Listing
            </a>
            <a href="/listings/dashboard" className="classified-create-link">
              Manage Listings
            </a>
          </div>
          <div className="classified-filters-tags" id="classified-filters-tags">
            <input
              type="text"
              placeholder="search"
              id="listings-search"
              autoComplete="off"
              defaultValue={query}
              onKeyUp={this.debouncedClassifiedListingSearch}
            />
            {clearQueryButton}
            {selectedTags}
          </div>
        </div>
        <div className="classifieds-columns" id="classified-listings-results">
          {allListings}
        </div>
        {nextPageButt}
        {modal}
      </div>
    );
  }
}

Listings.displayName = 'Classified Listings';
