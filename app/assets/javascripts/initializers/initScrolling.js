/* global insertAfter, insertArticles, buildArticleHTML, nextPage:writable, fetching:writable, done:writable, InstantClick */

// The purpose of initScrolling is to start paginating the page once you reach the bottom of the page.
// It does this for majority of the views on the dashboard page as well as the home feed.

var client;
/**
 *
 * @param {String} el is an HTML element that contains the container that we want to append items to. It contains id: indexContainer.
 * @param {String} endpoint is the relative URL of the endpoint to call to get the data
 * @param {Function} insertCallback is a function from the return of the callback function (insertNext). The function is passed the data as an argument to build the HTML.
 * @returns nil but calls the insertCallback (i.e. the insertEntries function) with the data as an argument to update the HTML. It also handles the loading spinner.
 */
function fetchNext(el, endpoint, insertCallback) {
  var indexParams = JSON.parse(el.dataset.params);
  // I change the name of the param from "action" to "controller_action" prior to the fetch because Rails ignores the
  // "action" param in the corresponding endpoint controller because it is a reserved word in Rails. Based on the above
  // I thought it would be safe to do the param name update for now until we can refactor this file and change the coupled architecture.
  // "action" renamed to "controller_action" is the name of the action from the originating server side request e.g. hidden_tags in the dashboard_controller.
  const updatedIndexParams = {};
  if (indexParams['action']) {
    delete Object.assign(updatedIndexParams, indexParams, {
      ['controller_action']: indexParams['action'],
    })['action'];
  }

  var urlParams = new URLSearchParams(updatedIndexParams).toString();
  if (urlParams.indexOf('q=') > -1) {
    return;
  }

  var fetchUrl =
    `${endpoint}?page=${nextPage}&${urlParams}&signature=${parseInt(
      Date.now() / 400000,
      10,
    )}`.replace('&&', '&');
  window
    .fetch(fetchUrl)
    .then(function handleResponse(response) {
      response.json().then(function insertEntries(entries) {
        nextPage += 1;
        insertCallback(entries);
        if (entries.length === 0) {
          const loadingElement = document.getElementById('loading-articles');
          if (loadingElement) {
            loadingElement.style.display = 'none';
          }
          done = true;
        }
      });
    })
    .catch(function logError(err) {
      // eslint-disable-next-line no-console
      console.log(err);
    });
}

/**
 *
 * @param {*} params are the dataset params on an wrapping container like 'index-container'. It contains the action and the elID.
 * The elID is the id of the element that we are appending to.
 * The action like 'following_tags' is the action that we are taking.
 * @param {*} buildCallback is the callback function (the buildFollowsHTML function) that will be called after the data is fetched.
 * It will be passed the data as an argument, and insert the HTML into the DOM.
 * @returns a function that will be called after the data is fetched from the caller.
 */
function insertNext(params, buildCallback) {
  return function insertEntries(entries = []) {
    var indexContainer = document.getElementById('index-container');
    var containerAction =
      JSON.parse(indexContainer.dataset.params).action || null;
    var action = params.action || null;
    var matchingAction = action === containerAction;
    var list = document.getElementById(params.listId || 'sublist');
    var newFollowersHTML = '';
    entries.forEach(function insertAnEntry(entry) {
      let existingEl = document.getElementById(
        (params.elId || 'element') + '-' + entry.id,
      );
      if (!existingEl) {
        var newHTML = buildCallback(entry);
        newFollowersHTML += newHTML;
      }
    });

    var followList = document.getElementById('following-wrapper');
    if (followList && matchingAction) {
      followList.insertAdjacentHTML('beforeend', newFollowersHTML);
    }
    if (nextPage > 0) {
      fetching = false;
    }
  };
}

/**
 * Constructs the HTML for a follows entry using the data from the follows entries object.
 *
 * @param {*} follows is the entries for the follows that we are building HTML for.
 * @returns an HTML block for the follows.
 */
function buildFollowsHTML(follows) {
  return (
    '<div class="crayons-card p-4 m:p-6 flex s:grid single-article" id="follows-' +
    follows.id +
    '">' +
    '<a href="' +
    follows.path +
    '" class="crayons-avatar crayons-avatar--2xl s:mb-2 s:mx-auto">' +
    '<img alt="@' +
    follows.username +
    ' profile image" class="crayons-avatar__image" src="' +
    follows.profile_image +
    '" />' +
    '</a>' +
    '<div class="pl-4 s:pl-0 self-center">' +
    '<h3 class="s:mb-1 p-0">' +
    '<a href="' +
    follows.path +
    '">' +
    follows.name +
    '</a>' +
    '</h3>' +
    '<p class="s:mb-4">' +
    '<a href="' +
    follows.path +
    '" class="crayons-link crayons-link--secondary">' +
    '@' +
    follows.username +
    '</a>' +
    '</p>' +
    '</div>' +
    '</div>'
  );
}

/**
 * Constructs the HTML for a tag entry using the data from the tag object.
 * @param {*} tag is the entry for which we are building HTML for.
 * @returns an HTML block for a tag follow.
 */
function buildTagsHTML(tag) {
  let followingButtonContainer = '';
  let unhideButtonContainer = '';

  if (tag.explicit_points < 0) {
    unhideButtonContainer = `<div>
        <button class="crayons-btn crayons-btn--danger unhide-button">Unhide</button>
      </div>`;
  }

  if (tag.explicit_points >= 0) {
    followingButtonContainer = `<div class="flex justify-between">
      <div>
        <button class="c-btn c-btn--secondary follow-button" aria-label="Following tag:${tag.name}">Following</button>
      </div>
      <div class="dropdown-trigger-container relative">
        <button type="button" aria-label="Unhide tag: ${tag.name}" class="c-btn c-btn--icon-alone dropdown-trigger" id="options-dropdown-trigger-${tag.tag_id}" aria-haspopup="true" aria-expanded="false" aria-controls="options-dropdown">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" class="crayons-icon" role="img" aria-labelledby="arimcllskwkmbfpxyu52b8vzin20raon"><title id="arimcllskwkmbfpxyu52b8vzin20raon">Options</title><path fill-rule="evenodd" clip-rule="evenodd" d="M7 12a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0zm5 2a2 2 0 100-4 2 2 0 000 4z"></path></svg>
        </button>
        <div class="crayons-dropdown right-0 left-0 s:left-auto" id="options-dropdown-${tag.tag_id}">
          <ul class="p-0">
            <li>
              <button type="button" class="hide-button c-btn w-100 align-left flex items-center" aria-label="Hide tag: ${tag.name}">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" class="crayons-icon" role="img" aria-labelledby="avelns726vzvmu4rpqxq8olxhll9obh"><title id="avelns726vzvmu4rpqxq8olxhll9obh">Hide tag</title>
                  <path d="M17.882 19.297A10.95 10.95 0 0 1 12 21c-5.392 0-9.878-3.88-10.82-9a10.982 10.982 0 0 1 3.34-6.066L1.393 2.808l1.415-1.415 19.799 19.8-1.415 1.414-3.31-3.31zM5.935 7.35A8.965 8.965 0 0 0 3.223 12a9.006 9.006 0 0 0 13.2 5.838l-2.027-2.028A4.5 4.5 0 0 1 8.19 9.604L5.935 7.35zm6.979 6.978-3.242-3.242a2.5 2.5 0 0 0 3.24 3.241l.002.001zm7.893 2.264-1.431-1.43a8.936 8.936 0 0 0 1.4-3.162A9.006 9.006 0 0 0 9.553 5.338L7.974 3.76A10.99 10.99 0 0 1 12 3c5.392 0 9.878 3.88 10.819 9a10.949 10.949 0 0 1-2.012 4.592zm-9.084-9.084a4.5 4.5 0 0 1 4.769 4.77l-4.77-4.77z"></path>
                </svg>
                <span class="ml-2">Hide tag</span>
              </button>
            </li>
          </ul>
        </div>
      </div>
    </div>`;
  }

  let short_summary = '';
  if (tag.short_summary) {
    short_summary = `<p class="mb-6 fs-s color-base-70 truncate-at-3">${tag.short_summary}</p>`;
  }

  // TODO: remove the data-follow-id and the data-tag-id in the child components
  return `
  <div class="dashboard__tag__container crayons-card p-3 pt-2 m:p-5 m:pt-4 relative flex flex-col single-article break-word content-center" id="follows-${
    tag.id
  }" data-follow-id="${tag.id}" data-tag-id="${tag.tag_id}">
    <div class="mb-1 flex items-center justify-between">
      <h4 class="-ml-2">
      <a href="/t/${tag.name}" class="crayons-tag crayons-tag--l">
        <span class="crayons-tag__prefix">#</span>${tag.name}
      </a>
      </h4>
      <div class="fs-xs color-base-60">${tag.taggings_count.toLocaleString()} posts</div>
    </div>
    ${short_summary}

    ${unhideButtonContainer}
    ${followingButtonContainer}
  </div>`;
}

/**
 * Fetches the next page for the given element.
 *
 * @param {*} el is the element that we are fetching the next page for.
 * @returns nil but carries out actions to fetch, build and insert the HTML into the DOM for the next page
 */
function fetchNextFollowingPage(el) {
  var indexParams = JSON.parse(el.dataset.params);
  var action = indexParams.action;
  if (action.includes('users')) {
    fetchNext(
      el,
      '/followings/users',
      insertNext({ elId: 'follows', action }, buildFollowsHTML),
    );
  } else if (action.includes('podcasts')) {
    fetchNext(
      el,
      '/followings/podcasts',
      insertNext({ elId: 'follows', action }, buildFollowsHTML),
    );
  } else if (action.includes('organizations')) {
    fetchNext(
      el,
      '/followings/organizations',
      insertNext({ elId: 'follows', action }, buildFollowsHTML),
    );
  } else if (action.includes('hidden_tags')) {
    fetchNext(
      el,
      '/followings/tags',
      insertNext({ elId: 'follows', action }, buildTagsHTML),
    );
  } else {
    // This "else" accounts for `followings_tags`, it would make more sense to explicitly check for
    // the condition rather than have a catch-all else statement. Hence, we need to double check
    // what cases the catch-all cover and then move it into an explicit condition.
    fetchNext(
      el,
      '/followings/tags',
      insertNext({ elId: 'follows', action }, buildTagsHTML),
    );
  }
}

function fetchNextFollowersPage(el) {
  fetchNext(
    el,
    '/api/followers/users',
    insertNext({ elId: 'follows' }, buildFollowsHTML),
  );
}

function buildVideoArticleHTML(videoArticle) {
  return `<a href="${videoArticle.path}" id="video-article-${videoArticle.id}" class="crayons-card media-card">
    <div class="media-card__artwork">
      <img src="${videoArticle.cloudinary_video_url}" class="w-100 object-cover block aspect-16-9 h-auto" width="320" height="180" alt="${videoArticle.title}">
      <span class="media-card__artwork__badge">${videoArticle.video_duration_in_minutes}</span>
    </div>
    <div class="media-card__content">
      <h2 class="fs-base mb-2 fw-medium">${videoArticle.title}</h2>
      <small class="fs-s">
        ${videoArticle.user.name}
      </small>
    </div>
  </a>`;
}

function insertVideos(videoArticles) {
  var list = document.getElementById('subvideos');
  var newVideosHTML = '';
  videoArticles.forEach(function insertAVideo(videoArticle) {
    var existingEl = document.getElementById(
      'video-article-' + videoArticle.id,
    );
    if (!existingEl) {
      var newHTML = buildVideoArticleHTML(videoArticle);
      newVideosHTML += newHTML;
    }
  });

  var distanceFromBottom =
    document.documentElement.scrollHeight - document.body.scrollTop;

  var parentNode = document.querySelector('.js-video-collection');
  var frag = document.createRange().createContextualFragment(newVideosHTML);
  parentNode.appendChild(frag);

  if (nextPage > 0) {
    fetching = false;
  }
}

function fetchNextVideoPage(el) {
  fetchNext(el, '/api/videos', insertVideos);
}

function insertArticles(articles) {
  var list = document.getElementById('substories');
  var newArticlesHTML = '';
  var el = document.getElementById('home-articles-object');
  var currentUser = userData();
  var currentUserId = currentUser && currentUser.id;
  if (el) {
    el.outerHTML = '';
  }
  articles.forEach(function insertAnArticle(article) {
    var existingEl = document.getElementById('article-link-' + article.id);
    if (
      ![
        '/',
        '/top/week',
        '/top/month',
        '/top/year',
        '/top/infinity',
        '/latest',
      ].includes(window.location.pathname) &&
      existingEl &&
      existingEl.parentElement &&
      existingEl.parentElement.classList.contains('crayons-story') &&
      !document.getElementById('video-player-' + article.id)
    ) {
      existingEl.parentElement.outerHTML = buildArticleHTML(
        article,
        currentUserId,
      );
    } else if (!existingEl) {
      var newHTML = buildArticleHTML(article, currentUserId);
      newArticlesHTML += newHTML;
      initializeReadingListIcons();
    }
  });
  var distanceFromBottom =
    document.documentElement.scrollHeight - document.body.scrollTop;
  var newNode = document.createElement('div');
  newNode.classList.add('paged-stories');
  newNode.innerHTML = newArticlesHTML;

  newNode.addEventListener('click', (event) => {
    const { classList } = event.target;

    // This looks a little messy, but it's the only
    // way to make the entire card clickable.
    if (
      classList.contains('crayons-story') ||
      classList.contains('crayons-story__top') ||
      classList.contains('crayons-story__body') ||
      classList.contains('crayons-story__indention') ||
      classList.contains('crayons-story__title') ||
      classList.contains('crayons-story__tags') ||
      classList.contains('crayons-story__bottom')
    ) {
      let element = event.target;
      let { articlePath } = element.dataset;

      while (!articlePath) {
        articlePath = element.dataset.articlePath;
        element = element.parentElement;
      }

      InstantClick.preload(articlePath);
      InstantClick.display(articlePath);
    }
  });

  var singleArticles = document.querySelectorAll(
    '.single-article, .crayons-story',
  );
  var lastElement = singleArticles[singleArticles.length - 1];
  insertAfter(newNode, lastElement);
  if (nextPage > 0) {
    fetching = false;
  }
}

function paginate(tag, params, requiresApproval) {
  const searchHash = Object.assign(
    { per_page: 15, page: nextPage },
    JSON.parse(params),
  );

  if (tag && tag.length > 0) {
    searchHash.tag_names = searchHash.tag_names || [];
    searchHash.tag_names.push(tag);
  }
  searchHash.approved = requiresApproval === 'true' ? 'true' : '';

  var homeEl = document.getElementById('index-container');
  if (homeEl.dataset.feed === 'base-feed') {
    searchHash.class_name = 'Article';
    const isHomePageFeed = window.location.pathname == '/';
    if (isHomePageFeed && userData()) {
      const hidden_tags = JSON.parse(userData().followed_tags).reduce(function (
        array,
        tag,
      ) {
        if (tag.points < 0) {
          array.push(tag.name);
        }
        return array;
      },
      []);

      searchHash.hidden_tags = hidden_tags;
    }
  } else if (homeEl.dataset.feed === 'latest') {
    searchHash.class_name = 'Article';
    searchHash.sort_by = 'published_at';
  } else {
    searchHash.class_name = 'Article';
    searchHash['published_at[gte]'] = homeEl.dataset.articlesSince;
    searchHash.sort_by = 'public_reactions_count';
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
      nextPage += 1;
      insertArticles(content.result);
      const checkBlockedContentEvent = new CustomEvent('checkBlockedContent');
      window.dispatchEvent(checkBlockedContentEvent);
      initializeReadingListIcons();
      if (content.result.length === 0) {
        const loadingElement = document.getElementById('loading-articles');
        if (loadingElement) {
          loadingElement.style.display = 'none';
        }
        done = true;
      }
    });
}

function fetchNextPageIfNearBottom() {
  var indexContainer = document.getElementById('index-container');
  var elCheck = indexContainer && !document.getElementById('query-wrapper');
  if (!elCheck) {
    return;
  }

  var indexWhich = indexContainer.dataset.which;

  var fetchCallback;
  var scrollableElem;

  if (indexWhich === 'videos') {
    scrollableElem = document.getElementById('main-content');
    fetchCallback = function fetch() {
      fetchNextVideoPage(indexContainer);
    };
  } else if (indexWhich === 'followers') {
    scrollableElem = document.getElementById('user-dashboard');
    fetchCallback = function fetch() {
      fetchNextFollowersPage(indexContainer);
    };
  } else if (indexWhich === 'following') {
    scrollableElem = document.getElementById('user-dashboard');
    fetchCallback = function fetch() {
      fetchNextFollowingPage(indexContainer);
    };
  } else {
    scrollableElem =
      document.getElementById('main-content') ||
      document.getElementById('articles-list');

    fetchCallback = function fetch() {
      paginate(
        indexContainer.dataset.tag,
        indexContainer.dataset.params,
        indexContainer.dataset.requiresApproval,
      );
    };
  }

  if (
    !done &&
    !fetching &&
    window.scrollY > scrollableElem.scrollHeight - 3700
  ) {
    fetching = true;
    fetchCallback();
  }
}

/**
 * Checks if the user is near the bottom of the page and if so, fetches the next page.
 * It also sets up an interval to check if the user is near the bottom of the page.
 */
function checkIfNearBottomOfPage() {
  const loadingElement = document.getElementById('loading-articles');
  if (
    (document.getElementsByClassName('crayons-story').length < 2 &&
      document.getElementsByClassName('single-article').length < 2) ||
    window.location.search.indexOf('q=') > -1
  ) {
    if (loadingElement) {
      loadingElement.style.display = 'none';
    }
    done = true;
  } else if (loadingElement) {
    loadingElement.style.display = 'block';
  }

  fetchNextPageIfNearBottom();
  setInterval(function handleInterval() {
    fetchNextPageIfNearBottom();
  }, 210);
}

/**
 * Initializes the scrolling for the page. It looks for the index-container element and if it exists, it sets up the scrolling.
 */
function initScrolling() {
  var elCheck = document.getElementById('index-container');

  if (elCheck) {
    initScrolling.called = true;
    checkIfNearBottomOfPage();
  }
}
