/* global insertAfter, insertArticles, buildArticleHTML, nextPage:writable, fetching:writable, done:writable, InstantClick */

var client;

function fetchNext(el, endpoint, insertCallback) {
  var indexParams = JSON.parse(el.dataset.params);
  var urlParams = Object.keys(indexParams)
    .map(function handleMap(k) {
      return encodeURIComponent(k) + '=' + encodeURIComponent(indexParams[k]);
    })
    .join('&');
  if (urlParams.indexOf('q=') > -1) {
    return;
  }
  var fetchUrl = (
    endpoint +
    '?page=' +
    nextPage +
    '&' +
    urlParams +
    '&signature=' +
    parseInt(Date.now() / 400000, 10)
  ).replace('&&', '&');
  window
    .fetch(fetchUrl)
    .then(function handleResponse(response) {
      response.json().then(function insertEntries(entries) {
        nextPage += 1;
        insertCallback(entries);
        if (entries.length === 0) {
          document.getElementById('loading-articles').style.display = 'none';
          done = true;
        }
      });
    })
    .catch(function logError(err) {
      // eslint-disable-next-line no-console
      console.log(err);
    });
}

function insertNext(params, buildCallback) {
  return function insertEntries(entries) {
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
    followList.insertAdjacentHTML('beforeend', newFollowersHTML);
    if (nextPage > 0) {
      fetching = false;
    }
  };
}

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

function buildTagsHTML(tag) {
  var antifollow = '';
  if (tag.points < 0) {
    antifollow =
      '<span class="crayons-indicator crayons-indicator--critical crayons-indicator--outlined" title="This tag has negative follow weight">Anti-follow</span>';
  }

  return `<div class="crayons-card p-4 m:p-6 flex flex-col single-article" id="follows-${tag.id}" style="border: 1px solid ${tag.color}; box-shadow: 3px 3px 0 ${tag.color}">
    <h3 class="s:mb-1 p-0 fw-medium">
      <a href="/t/${tag.name}" class="crayons-tag crayons-tag--l">
        <span class="crayons-tag__prefix">#</span>${tag.name}
      </a>
      ${antifollow}
    </h3>
    <p class="grid-cell__summary truncate-at-3"></p>
    <input name="follows[][id]" id="follow_id_${tag.name}" type="hidden" form="follows_update_form" value="${tag.id}">
    <input step="any" class="crayons-textfield flex-1 fs-s" required="required" type="number" form="follows_update_form" value="${tag.points}" name="follows[][explicit_points]" id="follow_points_${tag.name}" aria-label="${tag.name} tag weight">
  </div>`;
}

function fetchNextFollowingPage(el) {
  var indexParams = JSON.parse(el.dataset.params);
  var action = indexParams.action;
  if (action.includes('users')) {
    fetchNext(
      el,
      '/followings/users',
      insertNext({ elId: 'follows' }, buildFollowsHTML),
    );
  } else if (action.includes('podcasts')) {
    fetchNext(
      el,
      '/followings/podcasts',
      insertNext({ elId: 'follows' }, buildFollowsHTML),
    );
  } else if (action.includes('organizations')) {
    fetchNext(
      el,
      '/followings/organizations',
      insertNext({ elId: 'follows' }, buildFollowsHTML),
    );
  } else {
    fetchNext(
      el,
      '/followings/tags',
      insertNext({ elId: 'follows' }, buildTagsHTML),
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
  return (
    '<a class="single-video-article single-article" href="' +
    videoArticle.path +
    '" id="video-article-' +
    videoArticle.id +
    '">\n' +
    '  <div class="video-image" style="background-image: url(' +
    videoArticle.cloudinary_video_url +
    ')">\n' +
    '     <span class="video-timestamp">' +
    videoArticle.video_duration_in_minutes +
    '</span>\n' +
    '   </div>\n' +
    '   <p><strong>' +
    videoArticle.title +
    '</strong></p>\n' +
    '  <p>' +
    videoArticle.user.name +
    '</p>\n' +
    '</a>'
  );
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
  var newNode = document.createElement('div');
  newNode.innerHTML = newVideosHTML;
  newNode.className += 'video-collection';
  var singleArticles = document.querySelectorAll(
    '.single-article, .crayons-story',
  );
  var lastElement = singleArticles[singleArticles.length - 1];
  insertAfter(newNode, lastElement);
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
      existingEl.parentElement.outerHTML = buildArticleHTML(article);
    } else if (!existingEl) {
      var newHTML = buildArticleHTML(article);
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

function fetchNextPodcastPage(el) {
  fetchNext(el, '/api/podcast_episodes', insertArticles);
}

function paginate(tag, params, requiresApproval) {
  const searchHash = {
    ...{ per_page: 15, page: nextPage },
    ...JSON.parse(params),
  };

  if (tag && tag.length > 0) {
    searchHash.tag_names = searchHash.tag_names || [];
    searchHash.tag_names.push(tag);
  }
  searchHash.approved = requiresApproval === 'true' ? 'true' : '';

  var homeEl = document.getElementById('index-container');
  if (homeEl.dataset.feed === 'base-feed') {
    searchHash.class_name = 'Article';
  } else if (homeEl.dataset.feed === 'latest') {
    searchHash.class_name = 'Article';
    searchHash.sort_by = 'published_at';
  } else {
    searchHash.class_name = 'Article';
    searchHash['published_at[gte]'] = homeEl.dataset.articlesSince;
    searchHash.sort_by = 'public_reactions_count';
  }

  // Brute force copying code from a utlity for quick fix
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
        document.getElementById('loading-articles').style.display = 'none';
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

  if (indexWhich === 'podcast-episodes') {
    scrollableElem = document.getElementById('main-content');
    fetchCallback = function fetch() {
      fetchNextPodcastPage(indexContainer);
    };
  } else if (indexWhich === 'videos') {
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

function checkIfNearBottomOfPage() {
  if (
    (document.getElementsByClassName('crayons-story').length < 2 &&
      document.getElementsByClassName('single-article').length < 2) ||
    window.location.search.indexOf('q=') > -1
  ) {
    document.getElementById('loading-articles').style.display = 'none';
    done = true;
  } else {
    document.getElementById('loading-articles').style.display = 'block';
  }
  fetchNextPageIfNearBottom();
  setInterval(function handleInterval() {
    fetchNextPageIfNearBottom();
  }, 210);
}

function initScrolling() {
  var elCheck = document.getElementById('index-container');

  if (elCheck) {
    initScrolling.called = true;
    checkIfNearBottomOfPage();
  }
}
