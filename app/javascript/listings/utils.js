/**
 * How many listings to show per page
 * @constant {number}
 */
export const LISTING_PAGE_SIZE = 75;

export function updateListings(classifiedListings) {
  const fullListings = [];

  classifiedListings.forEach((listing) => {
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
