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

  substories.innerHTML =
    '<div class="p-9 align-center crayons-card"><br></div>';
  if (document.getElementById('query-wrapper')) {
    search(query, filters, sortBy, sortDirection);
    initializeFilters(query, filters);
    initializeSortingTabs(query);
  }
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

function search(query, filters, sortBy, sortDirection) {
  const hashtags = query.match(/#\w+/g);
  const searchTerm = query.replace(/#/g, '').trim();
  let page = parseInt(
    filterXSS(getQueryParams(document.location.search).page),
    10,
  );
  page = Number.isNaN(page) ? 0 : page;
  const searchHash = { per_page: 30, page: page ? page : 0 };

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

      //puts paginator indicators
      if (content.links !== null) {
        document
          .getElementById('btn-pagination-container')
          .classList.remove('hidden');

        //prev and next buttons onclick event
        if (content.links.prev) {
          document.getElementById('previous-page').classList.remove('hidden');

          const url = new URL(content.links.prev);
          const page = new URLSearchParams(url.search).get('page');

          document.getElementById('previous-page').onclick = change_page(
            query,
            filters,
            sortBy,
            sortDirection,
            page,
          );
        } else {
          document.getElementById('previous-page').classList.add('hidden');
        }

        if (content.links.next) {
          document.getElementById('next-page').classList.add('remove');

          const url = new URL(content.links.next);
          const page = new URLSearchParams(url.search).get('page');
          document.getElementById('next-page').onclick = change_page(
            query,
            filters,
            sortBy,
            sortDirection,
            page,
          );
        } else {
          document.getElementById('next-page').classList.add('hidden');
        }

        const last_url = new URL(content.links.last);
        const total_pages = parseInt(
          new URLSearchParams(last_url.search).get('page'),
          10,
        );

        //create pagination number buttons
        const page_btns = [];
        if (total_pages > 5) {
          page_btns.push(
            `<button class="crayons-btn crayons-btn--outlined page-btn-js" data-page="0" type="button" aria-label="Page 1">1</button>`,
          );

          let i = 1;
          let j = 3;
          if (page > 2) {
            i = page >= total_pages - 3 ? total_pages - 4 : page - 1;
            j = page + 1 < total_pages ? page + 1 : page;

            page_btns.push(
              `<button class="crayons-btn crayons-btn--outlined page-btn-js" data-page="${
                i - 1
              }" type="button" aria-label="Page ${i - 1}">...</button>`,
            );
          }
          for (i; i <= j && i !== total_pages - 1; i++) {
            page_btns.push(
              `<button class="crayons-btn crayons-btn--outlined page-btn-js" data-page="${i}" type="button" aria-label="Page ${
                i + 1
              }">${i + 1}</button>`,
            );
          }

          if (j < total_pages - 2) {
            page_btns.push(
              `<button class="crayons-btn crayons-btn--outlined page-btn-js" data-page="${i}" type="button" aria-label="Page ${i}">...</button>`,
            );
          }

          page_btns.push(
            `<button class="crayons-btn crayons-btn--outlined page-btn-js" data-page="${
              total_pages - 1
            }" type="button" aria-label="Page ${total_pages}">${total_pages}</button>`,
          );
        } else {
          for (let i = 0; i < total_pages; i++) {
            page_btns.push(
              `<button class="crayons-btn crayons-btn--outlined page-btn-js" data-page="${i}" type="button" aria-label="Page ${
                i + 1
              }">${i + 1}</button>`,
            );
          }
        }

        //adds buttons onclick event
        document.getElementsByClassName('page-btn-container-js')[0].innerHTML =
          page_btns.join('');
        for (const dom_btn of document.getElementsByClassName('page-btn-js')) {
          dom_btn.onclick = change_page(
            query,
            filters,
            sortBy,
            sortDirection,
            dom_btn.dataset.page,
          );
        }

        //indicate current page
        const page_btn = document.querySelectorAll(
          `.page-btn-js[data-page="${page}"]`,
        )[0];
        page_btn.classList.remove('crayons-btn--outlined');
        page_btn.classList.add('crayons-btn');
      } else {
        document
          .getElementById('btn-pagination-container')
          .classList.add('hidden');
      }
    });
}

function change_page(query, filters, sortBy, sortDirection, target_page) {
  return function () {
    const current_params = new URLSearchParams(document.location.search);
    current_params.set('page', target_page);
    window.history.pushState(null, null, `?${current_params.toString()}`);
    window.history.replaceState(null, null, `?${current_params.toString()}`);
    search(query, filters, sortBy, sortDirection);
  };
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
