import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';

/**
 * Adds a "View Admin Profile" link visible only to admin users on profile pages.
 * The link is built client side so the admin URL isn't rendered for crawlers.
 * @function initAdminProfileLink
 * @returns {(void|undefined)} This function has no useable return value.
 */
export function initAdminProfileLink() {
  const linkWrapper = document.getElementById(
    'user-profile-dropdownmenu-admin-link-wrapper',
  );

  if (!linkWrapper) {
    // wrapper not always present when this is called
    return;
  }

  getUserDataAndCsrfTokenSafely().then(({ currentUser }) => {
    if (!currentUser || !currentUser.admin) {
      linkWrapper.remove();
      return;
    }

    const { path, text } = linkWrapper.dataset;
    const link = document.createElement('a');
    link.href = path;
    link.className = 'crayons-link crayons-link--block';
    link.dataset.noInstant = '';
    link.textContent = text;
    linkWrapper.replaceChildren(link);
  });
}
