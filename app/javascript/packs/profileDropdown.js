import { initBlock } from '../profileDropdown/blockButton';
import { initFlag } from '../profileDropdown/flagButton';
import { initSpam } from '../profileDropdown/spamButton';
import { initializeDropdown } from '@utilities/dropdownUtils';

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

  initButtons();
  profileDropdownDiv.dataset.dropdownInitialized = true;
}

initDropdown();
