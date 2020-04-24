/* global filterXSS */

function initializeUserProfileContent(user) {
  document.getElementById('sidebar-profile--avatar').src =
    user.profile_image_90;
  document.getElementById('sidebar-profile--avatar').alt = user.username;

  document.getElementById('sidebar-profile--name').innerHTML = filterXSS(
    user.name,
  );
  document.getElementById('sidebar-profile--username').innerHTML =
    '@' + user.username;
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

  followedTags.forEach((tag) => {
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
        butt.classList.remove('hidden');
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

function toggleModActionMenu() {
  document.querySelector('.mod-actions-menu').classList.toggle('hidden');
}

function initializeModActionsMenu(user) {
  const articlePath =
    document.getElementById('article-show-container').dataset.path + '/actions_panel';
  const articleAuthorId = document.getElementById('article-show-container')
    .dataset.authorId;
  const modActionsMenuHTML = '<iframe src="' + articlePath + '"></iframe>';
  const modActionsMenuIconHTML =
    '<div class="mod-actions-menu-btn" onclick="toggleModActionMenu()">' +
    '<svg xmlns="http://www.w3.org/2000/svg" width="54px" height="54px" viewBox="-8 -8 40 40" class="crayons-icon actions-menu-svg" role="img" aria-labelledby=""><title id="">Moderation</title><path d="M3.783 2.826L12 1l8.217 1.826a1 1 0 01.783.976v9.987a6 6 0 01-2.672 4.992L12 23l-6.328-4.219A6 6 0 013 13.79V3.802a1 1 0 01.783-.976zM5 4.604v9.185a4 4 0 001.781 3.328L12 20.597l5.219-3.48A4 4 0 0019 13.79V4.604L12 3.05 5 4.604zM13 10h3l-5 7v-5H8l5-7v5z"></path></svg>' +
    '</div>';

  if (user.id !== articleAuthorId && user.trusted) {
    document.querySelector('.mod-actions-menu').innerHTML = modActionsMenuHTML;
    document.getElementById(
      'mod-actions-menu-btn-area',
    ).innerHTML = modActionsMenuIconHTML;
  }
}

function initializeBaseUserData() {
  const user = userData();
  const userProfileLinkHTML =
    '<a href="/' +
    user.username +
    '" id="first-nav-link" class="crayons-link crayons-link--block"><div>' +
    '<span class="fw-medium block">' +
    user.name +
    '</span>' +
    '<small class="fs-s color-base-50">@' +
    user.username +
    '</small>' +
    '</div></a>';
  document.getElementById(
    'user-profile-link-placeholder',
  ).innerHTML = userProfileLinkHTML;
  document.getElementById('nav-profile-image').src = user.profile_image_90;
  initializeUserSidebar(user);
  addRelevantButtonsToArticle(user);
  addRelevantButtonsToComments(user);
  initializeModActionsMenu(user);
}
