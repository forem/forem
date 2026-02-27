import { initializeDropdown } from '@utilities/dropdownUtils';
import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';

function initDropdown() {
  const profileDropdownDiv = document.querySelector('.profile-dropdown');

  if (profileDropdownDiv.dataset.dropdownInitialized === 'true') {
    return;
  }

  if (!profileDropdownDiv) {
    return;
  }

  initializeDropdown({
    triggerElementId: 'organization-profile-dropdown',
    dropdownContentId: 'organization-profile-dropdownmenu',
  });

  // Add actual link location (SEO doesn't like these "useless" links, so adding in here instead of in HTML)
  const reportAbuseLink = profileDropdownDiv.querySelector(
    '.report-abuse-link-wrapper',
  );
  reportAbuseLink.innerHTML = `<a href="${reportAbuseLink.dataset.path}" class="crayons-link crayons-link--block">Report Abuse</a>`;
  const adminLink = profileDropdownDiv.querySelector('.admin-link-wrapper');
  getUserDataAndCsrfTokenSafely().then(({ currentUser }) => {
    if (currentUser?.admin) {
      adminLink.innerHTML = `<a href="${adminLink.dataset.path}" class="crayons-link crayons-link--block">${adminLink.dataset.text}</a>`;
    }
  });

  profileDropdownDiv.dataset.dropdownInitialized = true;
}

initDropdown();
