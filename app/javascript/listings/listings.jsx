import { h, Component } from 'preact';
import { SingleListing } from './singleListing';

export class Listings extends Component {
  state = {
    listings: [],
    query: '',
    tags: [],
    index: null,
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
    const algoliaId = document.querySelector("meta[name='algolia-public-id']")
    .content;
    const algoliaKey = document.querySelector("meta[name='algolia-public-key']")
      .content;
    const env = document.querySelector("meta[name='environment']").content;
    const client = algoliasearch(algoliaId, algoliaKey);
    const index = client.initIndex(`ClassifiedListing_${env}`);
    const container = document.getElementById('classifieds-index-container')
    const category = container.dataset.category || ''
    const allCategories = JSON.parse(container.dataset.allcategories || []);
    let tags = [];
    if (params.t) {
      tags = params.t.split(',')
    }
    const query = params.q || ''
    let listings = [];
    if (tags.length === 0 && query === '') {
      listings = JSON.parse(container.dataset.listings)
    }
    let openedListing = null;
    let slug = null;
    if (container.dataset.displayedlisting) {
      openedListing = JSON.parse(container.dataset.displayedlisting);
      slug = openedListing.slug;
      document.body.classList.add('modal-open');
    }
    t.setState({query, tags, index, category, allCategories, listings, openedListing, slug });
    t.listingSearch(query, tags, category, slug);
    t.setUser()

    document.body.addEventListener('keydown', t.handleKeyDown)
  }

  componentDidUpdate() {
    this.triggerMasonry()
  }

  componentWillUnmount() {
    document.body.removeEventListener('keydown', this.handleKeyDown)
  }

  addTag = (e, tag) => {
    e.preventDefault();
    const { query, tags, category } = this.state;
    const newTags = tags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag)
    }
    this.setState({tags: newTags, page: 0, listings: []})
    this.listingSearch(query, newTags, category, null)
    window.scroll(0,0)
  }

  removeTag = (e, tag) => {
    e.preventDefault();
    const { query, tags, category } = this.state;
    const newTags = tags;
    const index = newTags.indexOf(tag);
    if (newTags.indexOf(tag) > -1) {
      newTags.splice(index, 1);
    }
    this.setState({tags: newTags, page: 0, listings: []})
    this.listingSearch(query, newTags, category, null)
  }

  selectCategory = (e, cat) => {
    e.preventDefault();
    const { query, tags } = this.state;
    this.setState({category: cat, page: 0, listings: []})
    this.listingSearch(query, tags, cat, null)
  }

  handleKeyDown = (e) => {
    // Enable Escape key to close an open listing.
    if (this.openedListing !== null && e.key === 'Escape') {
      this.handleCloseModal()
    }
  }

  handleCloseModal = (e) => {
    const { query, tags, category } = this.state;
    this.setState({openedListing: null, page: 0})
    this.setLocation(query, tags, category, null);
    document.body.classList.remove('modal-open');
  }

  handleOpenModal = (e, listing) => {
    e.preventDefault();
    this.setState({openedListing: listing});
    window.history.replaceState(null, null, `/listings/${listing.category}/${listing.slug}`);
    this.setLocation(null, null, listing.category, listing.slug);
    document.body.classList.add('modal-open');
  }

  handleOpenMessageModal = (e, listing) => {
    e.preventDefault();
    console.log(listing);
    console.log("HEEEY ");
  }

  handleOpenModalAndMessage = (e, listing) => {
    this.handleOpenModal(e, listing);
    this.handleOpenMessageModal(e, listing);
  }

  handleDraftingMessage = (e) => {
    e.preventDefault();
    this.setState({ message: e.target.value })
  }

  handleSubmitMessage = (e) => {
    if (this.state.message.replace(/\s/g, '').length === 0) {
      e.preventDefault();
      return;
    }

    const formData = new FormData();
    formData.append('user_id', this.state.openedListing.user_id);
    formData.append('message', this.state.message)
    formData.append('controller', 'chat_channels');

    getCsrfToken()
      .then(sendFetch('chat-creation', formData))
      .then(() => {
        window.location.href = `/connect/@${this.state.openedListing.author.username}`;
      });
  }

  handleQuery = e => {
    const { tags, category } = this.state;
    this.setState({query: e.target.value, page: 0, listings: []})
    this.listingSearch(e.target.value, tags, category, null)
  }

  clearQuery = () => {
    const { tags, category } = this.state;
    document.getElementById('listings-search').value = '';
    this.setState({query: '', page: 0, listings: []});
    this.listingSearch('', tags, category, null);
  }

  getQueryParams = () => {
    let qs = document.location.search;
    qs = qs.split('+').join(' ');

    const params = {};
    let tokens;
    const re = /[?&]?([^=]+)=([^&]*)/g;

    // eslint-disable-next-line no-cond-assign
    while (tokens = re.exec(qs)) {
      params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
    }

    return params;
  }

  loadNextPage = () => {
    const { query, tags, category, slug, page } = this.state;
    this.setState({page: page + 1});
    this.listingSearch(query, tags, category, slug);
  }

  setUser = () => {
    const t = this;
    setTimeout(function() {
      if (window.currentUser && t.state.currentUserId === null) {
        t.setState({currentUserId: window.currentUser.id });
      }
    }, 300)
    setTimeout(function() {
      if (window.currentUser && t.state.currentUserId === null) {
        t.setState({currentUserId: window.currentUser.id });
      }
    }, 1000)
  }

  triggerMasonry = () => {
    resizeAllMasonryItems();
    setTimeout(function() {
      resizeAllMasonryItems();
    }, 1)
    setTimeout(function() {
      resizeAllMasonryItems();
    }, 3)
  }

  setLocation = (query, tags, category, slug) => {
    let newLocation = ''
    if (slug) {
      newLocation = `/listings/${category}/${slug}`;
    } else if (query.length > 0 && tags.length > 0) {
      newLocation = `/listings/${category}?q=${query}&t=${tags}`;
    } else if (query.length > 0){
      newLocation = `/listings/${category}?q=${query}`;
    } else if (tags.length > 0) {
      newLocation = `/listings/${category}?t=${tags}`;
    } else if (category.length > 0) {
      newLocation = `/listings/${category}`;
    } else {
      newLocation = '/listings'
    }
    window.history.replaceState(null, null, newLocation);
  }

  listingSearch(query, tags, category, slug) {
    const t = this;
    const { index, page, listings } = t.state;
    const filterObject = {tagFilters: tags, hitsPerPage: 75, page}
    if (category.length > 0) {
      filterObject.filters = `category:${category}`
    }
    index.search(query, filterObject)
    .then(function searchDone(content) {
      const fullListings = listings;
      content.hits.forEach(listing => {
        if (!listings.map(l => (l.id)).includes(listing.id)) {
          fullListings.push(listing)
        }
      });
      t.setState({listings: fullListings, initialFetch: false, showNextPageButt: content.hits.length === 75});
    });
    this.setLocation(query, tags, category, slug);
  }

  render() {
    const { listings, query, tags, category, allCategories, currentUserId, openedListing, showNextPageButt, initialFetch } = this.state;
    const allListings = listings.map(listing => (
      <SingleListing
        onAddTag={this.addTag}
        onChangeCategory={this.selectCategory}
        listing={listing}
        currentUserId={currentUserId}
        onOpenModal={this.handleOpenModal}
        onMessageModal={this.handleOpenModalAndMessage}
        isOpen={false}
      />
    ));
    const selectedTags = tags.map(tag => (
      <span className="classified-tag">
        <a href='/listings?tags=' className='tag-name' onClick={e => this.removeTag(e, tag)} data-no-instant>
          <span>{tag}</span>
          <span className='tag-close' onClick={e => this.removeTag(e, tag)} data-no-instant>×</span>
        </a>
      </span>
    ))
    const categoryLinks = allCategories.map(cat => (
      <a href={`/listings/${cat.slug}`} className={cat.slug === category ? 'selected' : ''} onClick={e => this.selectCategory(e, cat.slug)} data-no-instant>{cat.name}</a>
    ))
    let nextPageButt = '';
    if (showNextPageButt) {
      nextPageButt = (
        <div className='classifieds-load-more-button'>
          <button onClick={e => this.loadNextPage(e)} type='button'>Load More Listings</button>
        </div>
      )
    }
    const clearQueryButton = query.length > 0 ? <button type="button" className='classified-search-clear' onClick={this.clearQuery}>×</button> : '';
    let modal = '';
    let modalBg = '';
    let messageModal = '';
    if (openedListing) {
      modalBg = <div className='classified-listings-modal-background' onClick={this.handleCloseModal} role='presentation' />
      if (openedListing.contact_via_connect && openedListing.user_id !== currentUserId) {
        messageModal = (
          <form id="new-message-form" className="listings-contact-via-connect" onSubmit={this.handleSubmitMessage}>
            <textarea value={this.state.message} onChange={this.handleDraftingMessage} id="new-message" rows="4" cols="70" placeholder="Enter your message here..." />
            <button type="submit" value="Submit" className="submit-button cta">SEND</button>
          </form>
        );
      }
      modal = (
        <div className="single-classified-listing-container">
          <SingleListing
            onAddTag={this.addTag}
            onChangeCategory={this.selectCategory}
            listing={openedListing}
            currentUserId={currentUserId}
            onOpenModal={this.handleOpenModal}
            onMessageModal={this.handleOpenMessageModal}
            isOpen
          />
          {messageModal}
        </div>
      )
    }
    if (initialFetch) {
      this.triggerMasonry();
    }
    return (
      <div className="listings__container">
        {modalBg}
        <div className="classified-filters">
          <div className="classified-filters-categories">
            <a href="/listings" className={category === '' ? 'selected' : ''} onClick={e => this.selectCategory(e, '')} data-no-instant>all</a>
            {categoryLinks}
            <a href='/listings/new' className='classified-create-link'>Create a Listing</a>
          </div>
          <div className="classified-filters-tags" id="classified-filters-tags">
            <input type="text" placeholder="search" id="listings-search" autoComplete="off" defaultValue={query} onKeyUp={e => this.handleQuery(e)} />
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
    )
  }
}

function resizeMasonryItem(item){
  /* Get the grid object, its row-gap, and the size of its implicit rows */
  const grid = document.getElementsByClassName('classifieds-columns')[0];
  const rowGap = parseInt(window.getComputedStyle(grid).getPropertyValue('grid-row-gap'));
  const rowHeight = parseInt(window.getComputedStyle(grid).getPropertyValue('grid-auto-rows'));

  const rowSpan = Math.ceil((item.querySelector('.listing-content').getBoundingClientRect().height+rowGap)/(rowHeight+rowGap));

  /* Set the spanning as calculated above (S) */
  // eslint-disable-next-line no-param-reassign
  item.style.gridRowEnd = `span ${ rowSpan}`;
}
function resizeAllMasonryItems(){
  // Get all item class objects in one list
  const allItems = document.getElementsByClassName('single-classified-listing');

  /*
   * Loop through the above list and execute the spanning function to
   * each list-item (i.e. each masonry item)
   */
  // eslint-disable-next-line vars-on-top
  for(let i=0;i<allItems.length;i++){
    resizeMasonryItem(allItems[i]);
  }
}




Listings.displayName = 'Classified Listings';
