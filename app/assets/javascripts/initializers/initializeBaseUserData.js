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

function initializeProfileImage(user) {
  if (!document.getElementById('comment-primary-user-profile--avatar')) return;
  document.getElementById('comment-primary-user-profile--avatar').src =
    user.profile_image_90;
}

function initializeUserSidebar(user) {
  if (!document.getElementById('sidebar-nav')) return;
  initializeUserProfileContent(user);
}

function addRelevantButtonsToArticle(user) {
  var articleContainer = document.getElementById('article-show-container');
  if (articleContainer) {
    if (parseInt(articleContainer.dataset.authorId, 10) === user.id) {
      let actions = [
        `<a class="crayons-btn crayons-btn--s crayons-btn--secondary" href="${articleContainer.dataset.path}/edit" rel="nofollow">Edit</a>`,
      ];
      if (JSON.parse(articleContainer.dataset.published) === true) {
        actions.push(
          `<a class="crayons-btn crayons-btn--s crayons-btn--secondary ml-1" href="${articleContainer.dataset.path}/manage" rel="nofollow">Manage</a>`,
        );
      }
      if (user.pro) {
        actions.push(
          `<a class="crayons-btn crayons-btn--s crayons-btn--secondary ml-1" href="${articleContainer.dataset.path}/stats" rel="nofollow">Stats</a>`,
        );
      }
      document.getElementById('action-space').innerHTML = actions.join('');
    }
  }
}

function setCurrentUserToNavBar(user) {
  const userNavLink = document.getElementById('first-nav-link');
  userNavLink.href = `/${user.username}`;
  userNavLink.querySelector('span').textContent = user.name;
  userNavLink.querySelector('small').textContent = `@${user.username}`;
  document.getElementById('nav-profile-image').src = user.profile_image_90;
  if (user.admin) {
    document
      .querySelector('.js-header-menu-admin-link')
      .classList.remove('hidden');
  }
}

function initializeBaseUserData() {
  const user = userData();
  setCurrentUserToNavBar(user);
  initializeUserSidebar(user);
  initializeProfileImage(user);
  addRelevantButtonsToArticle(user);

}

function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}