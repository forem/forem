/**
 * How many listings to show per page
 * @constant {number}
 */
export const LISTING_PAGE_SIZE = 75;

export function updateListings(listings) {
  const fullListings = [];

  listings.forEach((listing) => {
    if (listing.bumped_at) {
      fullListings.push(listing);
    }
  });

  return fullListings;
}

export function getQueryParams() {
  let queryString = document.location.search;
  queryString = queryString.split('+').join(' ');

  const params = {};
  let tokens;
  const re = /[?&]?([^=]+)=([^&]*)/g;

  // eslint-disable-next-line no-cond-assign
  while ((tokens = re.exec(queryString))) {
    params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
  }

  return params;
}

function resizeMasonryItem(item) {
  /* Get the grid object, its row-gap, and the size of its implicit rows */
  const grid = document.getElementsByClassName('listings-columns')[0];
  const rowGap = parseInt(
    window.getComputedStyle(grid).getPropertyValue('grid-row-gap'),
    10,
  );
  const rowHeight = 0;
  const rowSpan = Math.ceil(
    (item.getElementsByClassName('listing-content')[0].getBoundingClientRect()
      .height +
      rowGap) /
      (rowHeight + rowGap),
  );

  /* Set the spanning as calculated above (S) */
  // eslint-disable-next-line no-param-reassign
  item.style.gridRowEnd = `span ${rowSpan}`;
}

export function resizeAllMasonryItems() {
  // Get all item class objects in one list
  const allItems = document.getElementsByClassName('single-listing');

  /*
   * Loop through the above list and execute the spanning function to
   * each list-item (i.e. each masonry item)
   */
  // eslint-disable-next-line vars-on-top
  for (let i = 0; i < allItems.length; i += 1) {
    resizeMasonryItem(allItems[i]);
  }
}

export function getLocation({ query = '', tags = [], category = '', slug }) {
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
  return newLocation;
}
