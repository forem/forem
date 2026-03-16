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
  if (adminLink) {
    getUserDataAndCsrfTokenSafely().then(({ currentUser }) => {
      if (currentUser?.admin) {
        const adminLinkAnchor = document.createElement('a');
        adminLinkAnchor.href = adminLink.dataset.path;
        adminLinkAnchor.className = 'crayons-link crayons-link--block';
        adminLinkAnchor.textContent = adminLink.dataset.text;
        adminLink.replaceChildren(adminLinkAnchor);
      }
    }).catch(() => {
      // Admin link is best-effort only on cached pages.
    });
  }

  profileDropdownDiv.dataset.dropdownInitialized = true;
}

initDropdown();
