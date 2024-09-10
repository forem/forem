/* global checkUserLoggedIn, showLoginModal, userData, buildArticleHTML, initializeReadingListIcons */
/* eslint no-undef: "error" */

// This is a lightweight version of the client, which we should be fine importing regardless of whether it is set up.
// Could be optimized for optional inclusion in the future.
import algoliasearch from 'algoliasearch/lite'

function getQueryParams(qs) {
  qs = qs.split('+').join(' ');

  const params = {},
    re = /[?&]?([^=]+)=([^&]*)/g;
  let tokens;

  while ((tokens = re.exec(qs))) {
    params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
  }

  return params;
}

const params = getQueryParams(document.location.search);
let algoliaSearchCompleted = false;

function searchMain(substories, loadingHTML) {
  const query = filterXSS(params.q);
  const filters = filterXSS(params.filters || 'class_name:Article');
  const sortBy = filterXSS(params.sort_by || '');
  const sortDirection = filterXSS(params.sort_direction || '');

  substories.innerHTML = loadingHTML;
  if (document.getElementById('query-wrapper')) {
    search(query, filters, sortBy, sortDirection);
    initializeFilters(query, filters);
    initializeSortingTabs(query, substories, loadingHTML);
  }
}

function initializeSortingTabs(query, substories, loadingHTML) {
  const sortingTabs = document.querySelectorAll(
    '#sorting-option-tabs .crayons-navigation__item',
  );

  for (let i = 0; i < sortingTabs.length; i++) {
    const tab = sortingTabs[i];

    tab.addEventListener('click', (e) => {
      const currentParams = getQueryParams(document.location.search);
      const filters = filterXSS(currentParams.filters);

      const { sortBy, sortDirection } = e.target.dataset;
      const sortString = buildSortString(sortBy, sortDirection);

      substories.innerHTML = loadingHTML;
      if (filters) {
        window.history.pushState(
          null,
          null,
          `/search?q=${query}&filters=${filters}${sortString}`,
        );
        search(query, filters, sortBy, sortDirection);
      } else {
        window.history.pushState(null, null, `/search?q=${query}${sortString}`);
        search(query, '', sortBy, sortDirection);
      }

      for (let j = 0; j < sortingTabs.length; j++) {
        if (sortingTabs[j] !== e.target) {
          sortingTabs[j].classList.remove('crayons-navigation__item--current');
          sortingTabs[j].setAttribute('aria-current', '');
        }
      }

      e.target.classList.add('crayons-navigation__item--current');
      e.target.setAttribute('aria-current', 'page');
    });
  }
}

function initializeFilters(query, filters) {
  const filterButts = document.getElementsByClassName('query-filter-button');
  for (let i = 0; i < filterButts.length; i++) {
    if (filters === filterButts[i].dataset.filter) {
      filterButts[i].classList.add('crayons-navigation__item--current');
    }
    filterButts[i].onclick = function (e) {
      const currentParams = getQueryParams(document.location.search);
      const sortBy = filterXSS(currentParams.sort_by);
      const sortDirection = filterXSS(currentParams.sort_direction);
      const sortString = buildSortString(sortBy, sortDirection);

      if (
        e.target.classList.contains('my-posts-query-button') &&
        !checkUserLoggedIn()
      ) {
        showLoginModal({
          referring_source: 'search',
          trigger: 'my_posts_filter',
        });
        return;
      }
      const filters = e.target.dataset.filter;
      window.history.pushState(
        null,
        null,
        `/search?q=${query}&filters=${filters}${sortString}`,
      );
      const { className } = e.target;
      for (let i = 0; i < filterButts.length; i++) {
        filterButts[i].classList.remove('crayons-navigation__item--current');
      }
      if (className.indexOf('crayons-navigation__item--current') === -1) {
        e.target.classList.add('crayons-navigation__item--current');
        window.history.replaceState(
          null,
          null,
          `/search?q=${query}&filters=${filters}${sortString}`,
        );
        search(query, filters, sortBy, sortDirection);
      } else {
        window.history.replaceState(
          null,
          null,
          `/search?q=${query}${sortString}`,
        );
        search(query, '', sortBy, sortDirection);
      }
    };
  }
}

function buildSortString(sortBy, sortDirection) {
  return sortBy && sortDirection
    ? `&sort_by=${sortBy}&sort_direction=${sortDirection}`
    : '';
}

function search(query, filters, sortBy, sortDirection) {
  const hashtags = query.match(/#\w+/g);
  const searchTerm = query.replace(/#/g, '').trim();
  const searchHash = { per_page: 60, page: 0 };

  if (sortBy && sortDirection) {
    searchHash.sort_by = sortBy;
    searchHash.sort_direction = sortDirection;
  }

  if (filters === 'MY_POSTS' && userData()) {
    searchHash.user_id = userData()['id'];
    searchHash.class_name = 'Article';
  }

  if (hashtags && hashtags.length > 0) {
    for (let i = 0; i < hashtags.length; i++) {
      hashtags[i] = hashtags[i].replace(/#/, '');
    }
    searchHash.tag_names = hashtags;
  }

  if (filters) {
    filters.split('&').forEach((filter) => {
      const [key, value] = filter.split(':');
      searchHash[key] = value;
    });
  }

  if (searchTerm) {
    searchHash.search_fields = searchTerm;
  }

  // Brute force copying code from a utility for quick fix
  const searchParams = new URLSearchParams();
  Object.keys(searchHash).forEach((key) => {
    const value = searchHash[key];
    if (Array.isArray(value)) {
      value.forEach((arrayValue) => {
        searchParams.append(`${key}[]`, arrayValue);
      });
    } else {
      searchParams.append(key, value);
    }
  });

  // Run Algolia code only if the ID is live.
  if (document.body.dataset.algoliaId?.length > 0 && !searchParams.toString().includes('MY_POSTS') && !algoliaSearchCompleted) {
    algoliaSearch(searchParams.toString());
    algoliaSearchCompleted = true;
    return;
  }

  fetch(`/search/feed_content?${searchParams.toString()}`, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((content) => {
      const resultDivs = [];
      const currentUser = userData();
      const currentUserId = currentUser && currentUser.id;
      content.result.forEach((story) => {
        resultDivs.push(buildArticleHTML(story, currentUserId));
      });
      document.getElementById('substories').innerHTML = resultDivs.join('');
      initializeReadingListIcons();
      document
        .getElementById('substories')
        .classList.add('search-results-loaded');
      if (content.result.length === 0) {
        document.getElementById('substories').innerHTML =
          '<div class="p-9 align-center crayons-card">No results match that query</div>';
      }
    });
}

function algoliaSearch(searchParams) {
  const paramsObj = getQueryParams(searchParams);
  const env = document.querySelector('meta[name="environment"]').content;
  const {algoliaId, algoliaSearchKey} = document.body.dataset;
  const client = algoliasearch(algoliaId, algoliaSearchKey);
  const indexName = paramsObj.sort_by ? `${paramsObj.class_name || 'Article'}_timestamp_${paramsObj.sort_direction}_${env}` : `${paramsObj.class_name || 'Article'}_${env}`;
  const index = client.initIndex(indexName); // Hardcoded to user for now
  // This is where we will add the functionality to get search results directly from index with client:
  index
    .search(paramsObj.search_fields, {
      hitsPerPage: paramsObj.per_page,
      queryType: 'prefixNone',  // Disable prefix searches
      page: paramsObj.page,
    })
    .then(({ hits }) => {
      const resultDivs = [];
      const currentUser = userData();
      const currentUserId = currentUser && currentUser.id;
      hits.forEach((story) => {
        story.class_name = paramsObj.class_name;
        story.id = story.objectID;
        // Add profile_image_90 to story object from profile image if profile_image_90 is not present
        resultDivs.push(buildArticleHTML(story, currentUserId));
      });
      document.getElementById('substories').innerHTML = resultDivs.join('');
      initializeReadingListIcons();
      document
        .getElementById('substories')
        .classList.add('search-results-loaded');
      if (hits.length === 0) {
        document.getElementById('substories').innerHTML =
          '<div class="p-9 align-center crayons-card">No results match that query</div>';
      }
    })
  .catch(err => {
    console.log('Algolia search error:') /* eslint-disable-line */
    console.log(err); /* eslint-disable-line */
  });
}

const waitingOnSearch = setInterval(() => {
  if (
    typeof search === 'function' &&
    typeof filterXSS === 'function' &&
    typeof buildArticleHTML === 'function'
  ) {
    clearInterval(waitingOnSearch);
    const substories = document.getElementById('substories');
    const loadingHTML = document.querySelector(
      'template[id=crayons-story-loading]',
    ).innerHTML;
    if (
      substories &&
      document.getElementsByClassName('search-results-loaded').length === 0
    ) {
      searchMain(substories, loadingHTML);
    }
  }
}, 1);
