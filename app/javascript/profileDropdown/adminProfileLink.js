import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';

/**
 * Adds a "View Admin Profile" link visible only to admin users on profile pages.
 * The anchor is only built client side for admins, so no crawlable link to the
 * admin page is rendered (the path itself is still present in a data attribute).
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
