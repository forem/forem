/* global filterXSS */
function initializeProfileImage(user) {
  if (!document.getElementById('comment-primary-user-profile--avatar')) return;
  document.getElementById('comment-primary-user-profile--avatar').src =
    user.profile_image_90;
}

function addRelevantButtonsToArticle(user) {
  var articleContainer = document.getElementById('article-show-container');

  if (
    articleContainer &&
    articleContainer.dataset.buttonsInitialized !== 'true'
  ) {
    let actions = [];
    const published = JSON.parse(articleContainer.dataset.published);

    if (parseInt(articleContainer.dataset.authorId, 10) === user.id) {
      actions.push(
        `<a class="crayons-btn crayons-btn--s crayons-btn--secondary" href="${articleContainer.dataset.path}/edit" rel="nofollow">Edit</a>`,
      );

      let clickToEditButton = document.getElementById('author-click-to-edit');
      if (clickToEditButton) {
        clickToEditButton.style.display = 'inline-block';
      }

      if (published === true) {
        actions.push(
          `<a class="crayons-btn crayons-btn--s crayons-btn--secondary ml-1" href="${articleContainer.dataset.path}/manage" rel="nofollow">Manage</a>`,
        );
      }

      actions.push(
        `<a class="crayons-btn crayons-btn--s crayons-btn--secondary ml-1" href="${articleContainer.dataset.path}/stats" rel="nofollow">Stats</a>`,
      );
    }

    const { articleId, pinnedArticleId } = articleContainer.dataset;

    // we hide the buttons for draft articles, for non admins and
    // if there's already a pinned post different from the current one
    if (
      published &&
      user.admin &&
      (articleId === pinnedArticleId || !pinnedArticleId)
    ) {
      const isArticlePinned = articleContainer.hasAttribute('data-pinned');
      const { pinPath } = articleContainer.dataset;

      actions.push(
        `<button
            id="js-${isArticlePinned ? 'unpin' : 'pin'}-article"
            class="crayons-btn crayons-btn--s crayons-btn--secondary ml-1"
            data-path="${pinPath}"
            data-article-id="${articleId}">${
          isArticlePinned ? 'Unpin' : 'Pin'
        } Post</button>`,
      );
    }

    document.getElementById('action-space').innerHTML = actions.join('');
    articleContainer.dataset.buttonsInitialized = 'true';
  }
}

function addRelevantButtonsToComments(user) {
  if (document.getElementById('comments-container')) {
    // buttons are actually <span>'s
    var settingsButts = document.getElementsByClassName('comment-actions');

    for (let i = 0; i < settingsButts.length; i += 1) {
      let butt = settingsButts[i];
      const { action, commentableUserId, userId } = butt.dataset;
      if (parseInt(userId, 10) === user.id && action === 'settings-button') {
        butt.innerHTML =
          '<a href="' +
          butt.dataset.path +
          '" rel="nofollow" class="crayons-link crayons-link--block" data-no-instant>Settings</a>';
        butt.classList.remove('hidden');
        butt.classList.add('block');
      }

      if (
        action === 'hide-button' &&
        parseInt(commentableUserId, 10) === user.id
      ) {
        butt.classList.remove('hidden');
        butt.classList.add('block');
      }
    }

    if (user.trusted) {
      var modButts = document.getElementsByClassName('mod-actions');
      for (let i = 0; i < modButts.length; i += 1) {
        let butt = modButts[i];
        if (butt.classList.contains('mod-actions-comment-button')) {
          butt.innerHTML =
            '<a href="' +
            butt.dataset.path +
            '" rel="nofollow" class="crayons-link crayons-link--block">Moderate</a>';
        }
        butt.className = 'mod-actions';
        butt.classList.remove('hidden');
        butt.classList.add('block');
      }
    }
  }
}

function setCurrentUserToNavBar(user) {
  const userNavLink = document.getElementById('first-nav-link');
  userNavLink.href = `/${user.username}`;
  userNavLink.getElementsByTagName('span')[0].textContent = user.name;
  userNavLink.getElementsByTagName(
    'small',
  )[0].textContent = `@${user.username}`;
  document.getElementById('nav-profile-image').src = user.profile_image_90;
  if (user.admin) {
    document
      .getElementsByClassName('js-header-menu-admin-link')[0]
      .classList.remove('hidden');
  }
}

function initializeBaseUserData() {
  const user = userData();
  setCurrentUserToNavBar(user);
  initializeProfileImage(user);
  addRelevantButtonsToArticle(user);
  addRelevantButtonsToComments(user);
}
