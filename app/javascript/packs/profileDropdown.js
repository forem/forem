import { initBlock } from '../profileDropdown/blockButton';
import { initFlag } from '../profileDropdown/flagButton';
import { initSpam } from '../profileDropdown/spamButton';
import { initializeDropdown } from '@utilities/dropdownUtils';
import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';

/* global userData */

function initButtons() {
  initBlock();
  initFlag();
  initSpam();
}

function initDropdown() {
  const profileDropdownDiv = document.querySelector('.profile-dropdown');

  if (profileDropdownDiv.dataset.dropdownInitialized === 'true') {
    return;
  }
  const currentUser = userData();

  if (!profileDropdownDiv) {
    // Hide this menu when user views their own profile
    return;
  }

  if (currentUser && currentUser.username === profileDropdownDiv.dataset.username) {
      profileDropdownDiv.style.display = 'none';
  }

  initializeDropdown({
    triggerElementId: 'user-profile-dropdown',
    dropdownContentId: 'user-profile-dropdownmenu',
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

  initButtons();
  profileDropdownDiv.dataset.dropdownInitialized = true;
}

initDropdown();
