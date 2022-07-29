/* global checkUserLoggedIn, showLoginModal, userData, buildArticleHTML, initializeReadingListIcons */
/* eslint no-undef: "error" */

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

function searchMain(substories) {
  const query = filterXSS(params.q);
  const filters = filterXSS(params.filters || 'class_name:Article');
  const sortBy = filterXSS(params.sort_by || '');
  const sortDirection = filterXSS(params.sort_direction || '');
  const page = parseInt(filterXSS(params.page || '0'), 10);

  substories.innerHTML =
    '<div class="p-9 align-center crayons-card"><br></div>';
  if (document.getElementById('query-wrapper')) {
    search(query, filters, sortBy, sortDirection, page);
    initializeFilters(query, filters);
    initializeSortingTabs(query);
  }
}

function fetchRecords(url) {
  fetch(url, {
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
      const { pages } = content.links ?? 0;
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
      if (pages > 1) {
        initializePagination(content.links);
        document
          .getElementById('btn-pagination-container')
          .classList.remove('hidden');
      } else {
        document
          .getElementById('btn-pagination-container')
          .classList.add('hidden');
      }
    });
}

function initializeSortingTabs(query) {
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
        showLoginModal();
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

function search(query, filters, sortBy, sortDirection, page = 0) {
  const hashtags = query.match(/#\w+/g);
  const searchTerm = query.replace(/#/g, '').trim();
  // The user pagination starts at 1 but in backend starts at zero.
  const searchHash = { per_page: 30, page: page === 0 ? page : page - 1 };

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

  const feedContentURL = `/search/feed_content?${searchParams.toString()}`;
  fetchRecords(feedContentURL);
}

function initializePagination(links) {
  const { first, last, next, prev, self, pages: totalPages } = links;

  const { pathname, search } = new URL(self);
  const currentPage = parseInt(new URLSearchParams(search).get('page'), 10);
  const previousButton = document.getElementById('previous-page');
  const nextButton = document.getElementById('next-page');
  const pageButtonContainer = document.getElementsByClassName(
    'page-btn-container-js',
  )[0];
  const pageButtons = () => {
    const firstPageButton = `<button
        id="first-page"
        class="crayons-btn crayons-btn--outlined"
        type="button"
        data-page="0"
        aria-label="Page 1">
          1
      </button>`;
    const lastPageButton = `<button
        id="last-page"
        class="crayons-btn crayons-btn--outlined"
        data-page="${totalPages - 1}"
        type="button" aria-label="Page ${totalPages}"
      >
          ${totalPages}
      </button>`;
    const numberPageButton = (pageNumber, isInterval) => {
      const buttonText = isInterval ? '...' : pageNumber;
      return `<button class="crayons-btn crayons-btn--outlined page-btn-js" data-page="${
        pageNumber - 1
      }" aria-label="Page ${pageNumber}" type="button">${buttonText}</button>`;
    };
    let pageNumberButtons;

    if (totalPages <= 5) {
      pageNumberButtons = [...Array(totalPages - 2)].map((_, index) =>
        numberPageButton(index + 2),
      );
    } else if (currentPage <= 3) {
      pageNumberButtons = [...Array(4)].map((_, index) => {
        const pageNumber = index + 2;
        return index === 3
          ? numberPageButton(pageNumber, true)
          : numberPageButton(pageNumber);
      });
    } else if (currentPage >= totalPages - 4) {
      pageNumberButtons = [...Array(4)].map((_, index) => {
        const pageNumber = index + totalPages - 4;
        return index === 0
          ? numberPageButton(pageNumber, true)
          : numberPageButton(pageNumber);
      });
    } else {
      pageNumberButtons = [...Array(5)].map((_, index) => {
        const pageNumber = index + currentPage - 1;
        return index === 0 || index === 4
          ? numberPageButton(pageNumber, true)
          : numberPageButton(pageNumber);
      });
    }

    return [firstPageButton, ...pageNumberButtons, lastPageButton].join('');
  };
  const updatePage = (targetPage) => {
    const newURL = new URLSearchParams(document.location.search);
    newURL.set('page', targetPage);
    window.history.pushState(null, null, `?${newURL.toString()}`);
    window.history.replaceState(null, null, `?${newURL.toString()}`);
  };

  pageButtonContainer.innerHTML = pageButtons();
  const pageButtonsElements = document.getElementsByClassName('page-btn-js');
  const activePageButton = document.querySelectorAll(
    `[data-page="${currentPage}"]`,
  )[0];

  // prev, next, first and last buttons onclick event
  !!prev &&
    (previousButton.onclick = () => {
      updatePage(currentPage);
      fetchRecords(prev);
    });
  !!next &&
    (nextButton.onclick = () => {
      updatePage(currentPage + 2);
      fetchRecords(next);
    });
  !!first &&
    (document.getElementById('first-page').onclick = () => {
      updatePage(1);
      fetchRecords(first);
    });
  !!last &&
    (document.getElementById('last-page').onclick = () => {
      updatePage(totalPages);
      fetchRecords(last);
    });

  // Page number buttons
  for (const button of pageButtonsElements) {
    const targetPage = button.dataset.page;
    const currentPage = new URLSearchParams(search);
    currentPage.set('page', targetPage);
    const destinationPageURL = `${pathname}?${currentPage.toString()}`;

    button.onclick = () => {
      updatePage(parseInt(targetPage, 10) + 1);
      fetchRecords(destinationPageURL);
    };
  }

  // Hide prev or next buttons
  currentPage === 0
    ? previousButton.classList.add('hidden')
    : previousButton.classList.remove('hidden');
  currentPage === totalPages - 1
    ? nextButton.classList.add('hidden')
    : nextButton.classList.remove('hidden');

  // Indicate current page
  activePageButton.classList.remove('crayons-btn--outlined');
  activePageButton.classList.add('crayons-btn');
}

const waitingOnSearch = setInterval(() => {
  if (
    typeof search === 'function' &&
    typeof filterXSS === 'function' &&
    typeof buildArticleHTML === 'function'
  ) {
    clearInterval(waitingOnSearch);
    const substories = document.getElementById('substories');
    if (
      substories &&
      document.getElementsByClassName('search-results-loaded').length === 0
    ) {
      searchMain(substories);
    }
  }
}, 1);
