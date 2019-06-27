/* globals userData, filterXSS */

function initializeUserProfileContent(user) {
  document.getElementById('sidebar-profile-pic').innerHTML =
    '<img alt="' +
    user.username +
    '" class="sidebar-profile-pic-img" src="' +
    user.profile_image_90 +
    '" />';
  document.getElementById('sidebar-profile-name').innerHTML = filterXSS(
    user.name,
  );
  document.getElementById('sidebar-profile-username').innerHTML =
    '@' + user.username;
  document.getElementById('sidebar-profile-snapshot-inner').href =
    '/' + user.username;
}

function initializeUserSidebar(user) {
  if (!document.getElementById('sidebar-nav')) return;
  initializeUserProfileContent(user);

  let followedTags = JSON.parse(user.followed_tags);
  const tagSeparatorLabel =
    followedTags.length === 0
      ? 'Follow tags to improve your feed'
      : 'Other Popular Tags';
  document.getElementById('tag-separator').innerHTML = tagSeparatorLabel;

  // sort tags by descending weigth, descending popularity and name
  followedTags.sort((tagA, tagB) => {
    return (
      tagB.points - tagA.points ||
      tagB.hotness_score - tagA.hotness_score ||
      tagA.name.localeCompare(tagB.name)
    );
  });

  let tagHTML = '';
  followedTags.forEach(tag => {
    var element = document.getElementById(
      'default-sidebar-element-' + tag.name,
    );
    tagHTML +=
      tag.points > 0.0
        ? '<div class="sidebar-nav-element" id="sidebar-element-' +
          tag.name +
          '">' +
          '<a class="sidebar-nav-link" href="/t/' +
          tag.name +
          '">' +
          '<span class="sidebar-nav-tag-text">#' +
          tag.name +
          '</span>' +
          '</a>' +
          '</div>'
        : '';
    if (element) element.remove();
  });
  document.getElementById('sidebar-nav-followed-tags').innerHTML = tagHTML;
  document.getElementById('sidebar-nav-default-tags').classList.add('showing');
}

function addRelevantButtonsToArticle(user) {
  var articleContainer = document.getElementById('article-show-container');
  if (articleContainer) {
    if (parseInt(articleContainer.dataset.authorId, 10) === user.id) {
      let actions = [
        `<a href="${articleContainer.dataset.path}/edit" rel="nofollow">EDIT</a>`,
      ];
      if (JSON.parse(articleContainer.dataset.published) === true) {
        actions.push(
          `<a href="${articleContainer.dataset.path}/manage" rel="nofollow">MANAGE</a>`,
        );
      }
      if (user.pro) {
        actions.push(
          `<a href="${articleContainer.dataset.path}/stats" rel="nofollow">STATS</a>`,
        );
      }
      document.getElementById('action-space').innerHTML = actions.join('');
    } else if (user.trusted) {
      document.getElementById('action-space').innerHTML =
        '<a href="' +
        articleContainer.dataset.path +
        '/mod" rel="nofollow">MODERATE <span class="post-word">POST</span></a>';
    }
  }
}

function addRelevantButtonsToComments(user) {
  if (document.getElementById('comments-container')) {
    var settingsButts = document.getElementsByClassName('comment-actions');

    for (let i = 0; i < settingsButts.length; i += 1) {
      let butt = settingsButts[i];
      if (parseInt(butt.dataset.userId, 10) === user.id) {
        butt.className = 'comment-actions';
        butt.style.display = 'inline-block';
      }
    }

    if (user.trusted) {
      var modButts = document.getElementsByClassName('mod-actions');
      for (let i = 0; i < modButts.length; i += 1) {
        let butt = modButts[i];
        butt.className = 'mod-actions';
        butt.style.display = 'inline-block';
      }
    }
  }
}

function initializeBaseUserData() {
  const user = userData();
  const userProfileLinkHTML =
    '<a href="/' +
    user.username +
    '" id="first-nav-link"><div class="option prime-option">@' +
    user.username +
    '</div></a>';
  document.getElementById(
    'user-profile-link-placeholder',
  ).innerHTML = userProfileLinkHTML;
  document.getElementById('nav-profile-image').src = user.profile_image_90;
  initializeUserSidebar(user);
  addRelevantButtonsToArticle(user);
  addRelevantButtonsToComments(user);
}
