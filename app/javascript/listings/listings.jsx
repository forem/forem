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
    t.setState({query, tags, index, category, allCategories, listings });
    t.listingSearch(params.q || '', tags, category);
    t.setUser()
  }

  addTag = (e, tag) => {
    e.preventDefault();
    const { query, tags, category } = this.state;
    const newTags = tags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag)
    }
    this.setState({tags: newTags})
    this.listingSearch(query, newTags, category)
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
    this.setState({tags: newTags})
    this.listingSearch(query, newTags, category)
  }

  selectCategory = (e, cat) => {
    e.preventDefault();
    const { query, tags } = this.state;
    this.setState({category: cat})
    this.listingSearch(query, tags, cat)
  }

  handleQuery = e => {
    const { tags, category } = this.state;
    this.setState({query: e.target.value})
    this.listingSearch(e.target.value, tags, category)
  }

  clearQuery = () => {
    const { tags, category } = this.state;
    document.getElementById('listings-search').value = '';
    this.setState({query: ''});
    this.listingSearch('', tags, category);
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

  listingSearch(query, tags, category) {
    const t = this;
    const filterObject = {tagFilters: tags, hitsPerPage: 120,}
    if (category.length > 0) {
      filterObject.filters = `category:${category}`
    }
    t.state.index.search(query, filterObject)
    .then(function searchDone(content) {
      if (t.state.initialFetch && t.state.category === '') {
        const fullListings = t.state.listings;
        content.hits.forEach(function(listing) {
          if (!t.state.listings.map(l => (l.id)).includes(listing.id)) {
            fullListings.push(listing)
          }
        });
        t.setState({listings: fullListings, initialFetch: false});
    } else {
      t.setState({listings: content.hits, initialFetch: false});
    }

    });
    let newLocation = ''
    if (query.length > 0 && tags.length > 0) {
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

  render() {
    const { listings, query, tags, category, allCategories, currentUserId } = this.state;
    const allListings = listings.map(listing => (
      <SingleListing
        onAddTag={this.addTag}
        onChangeCategory={this.selectCategory}
        listing={listing}
        currentUserId={currentUserId}
      />
    ));
    this.triggerMasonry()
    const selectedTags = tags.map(tag => (
      <span className="classified-tag">
        <a href='/listings?tags=' className='tag-name' onClick={e => this.removeTag(e, tag)} data-no-instant><span>{tag}</span><span className='tag-close' onClick={e => this.removeTag(e, tag)} data-no-instant>×</span></a>
      </span>
    ))
    const categoryLinks = allCategories.map(cat => (
      <a href={`/listings/${cat.slug}`} className={cat.slug === category ? 'selected' : ''} onClick={e => this.selectCategory(e, cat.slug)} data-no-instant>{cat.name}</a>
    ))
    const clearQueryButton = query.length > 0 ? <button type="button" className='classified-search-clear' onClick={this.clearQuery}>×</button> : '';
    return (
      <div>
        <div className="classified-filters">
          <div className="classified-filters-categories">
            <a href="/listings" className={category === '' ? 'selected' : ''} onClick={e => this.selectCategory(e, '')}  data-no-instant>all</a>
            {categoryLinks}
            <a href='/listings/new' className='classified-create-link'>Create a Listing</a>
          </div>
          <div className="classified-filters-tags" id="classified-filters-tags">
            <input type="text" placeholder="search" id="listings-search" autoComplete="off" defaultValue={query} onKeyUp={e => this.handleQuery(e)}/>{clearQueryButton}{selectedTags}
          </div>
        </div>
        <div className="classifieds-columns" id="classified-listings-results">
          {allListings}
        </div>
      </div>
)

    return <div className="github-repos">{allListings}</div>;
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
  for(var i=0;i<allItems.length;i++){
    resizeMasonryItem(allItems[i]);
  }
}




Listings.displayName = 'Classified Listings';
