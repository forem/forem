'use strict';

/* global userData, filterXSS */

function initializeUserProfileContent(user) {
  document.getElementById('sidebar-profile--avatar').src = user.profile_image_90;
  document.getElementById('sidebar-profile--avatar').alt = user.username;

  document.getElementById('sidebar-profile--name').innerHTML = filterXSS(
    user.name,
  );
  document.getElementById('sidebar-profile--username').innerHTML = '@' + user.username;
  document.getElementById('sidebar-profile').href = '/' + user.username;
}

function initializeUserSidebar(user) {
  if (!document.getElementById('sidebar-nav')) return;
  initializeUserProfileContent(user);

  let followedTags = JSON.parse(user.followed_tags);
  const tagSeparatorLabel =
    followedTags.length === 0
      ? 'Follow tags to improve your feed'
      : 'Other Popular Tags';

  followedTags.forEach(tag => {
    const element = document.getElementById(
      'default-sidebar-element-' + tag.name,
    );

    if (element) {
      element.remove();
    }
  });

  document.getElementById('tag-separator').innerHTML = tagSeparatorLabel;
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
    // buttons are actually <span>'s
    var settingsButts = document.getElementsByClassName('comment-actions');

    for (let i = 0; i < settingsButts.length; i += 1) {
      let butt = settingsButts[i];
      const { action, commentableUserId, userId } = butt.dataset;

      if (parseInt(userId, 10) === user.id) {
        butt.style.display = 'inline-block';
      }
      if (
        action === 'hide-button' &&
        parseInt(commentableUserId, 10) === user.id
      ) {
        butt.style.display = 'inline-block';
      } else if (
        action === 'hide-button' &&
        parseInt(commentableUserId, 10) !== user.id
      ) {
        butt.style.display = 'none';
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
    '<a href="/' + user.username + '" id="first-nav-link" class="crayons-link crayons-link--block"><div>' +
    '<span class="fw-medium block color-base-100">' + user.name +'</span>' +
    '<small class="fs-s color-base-50">@' + user.username + '</small>' +
    '</div></a>';
  document.getElementById(
    'user-profile-link-placeholder',
  ).innerHTML = userProfileLinkHTML;
  document.getElementById('nav-profile-image').src = user.profile_image_90;
  initializeUserSidebar(user);
  addRelevantButtonsToArticle(user);
  addRelevantButtonsToComments(user);
}
