'use strict';

function initializeUserProfilePage() {
  const profileDropdownDiv = document.getElementsByClassName(
    'profile-dropdown',
  )[0];
  if (profileDropdownDiv) {
    const currentUser = userData();
    if (
      currentUser &&
      currentUser.username === profileDropdownDiv.dataset.username
    ) {
      profileDropdownDiv.hidden = true;
    } else {
      profileDropdownDiv.hidden = false;
      const userProfileDropdownButton = document.getElementById(
        'user-profile-dropdown',
      );
      if (userProfileDropdownButton) {
        const userProfileDropdownMenu = document.getElementById(
          'user-profile-dropdownmenu',
        );
        userProfileDropdownButton.addEventListener('click', () => {
          userProfileDropdownMenu.classList.toggle('block');

          // Add actual link location (SEO doesn't like these "useless" links, so adding in here instead of in HTML)
          var reportAbuseLink = profileDropdownDiv.getElementsByClassName(
            'report-abuse-link-wrapper',
          )[0];
          reportAbuseLink.innerHTML = `<a href="${reportAbuseLink.dataset.path}" class="crayons-link crayons-link--block">Report Abuse</a>`;
        });
      }
    }
  }
}

function initializeProfileInfoToggle() {
  const infoPanels = document.getElementsByClassName('js-user-info')[0];
  const trigger = document.getElementsByClassName('js-user-info-trigger')[0];
  const triggerWrapper = document.getElementsByClassName(
    'js-user-info-trigger-wrapper',
  )[0];

  if (trigger && infoPanels) {
    trigger.addEventListener('click', () => {
      triggerWrapper.classList.replace('block', 'hidden');
      infoPanels.classList.replace('hidden', 'grid');
    });
  }
}

function initializeProfileBadgesToggle() {
  const badgesWrapper = document.getElementsByClassName('js-profile-badges')[0];
  const trigger = document.getElementsByClassName(
    'js-profile-badges-trigger',
  )[0];

  if (badgesWrapper && trigger) {
    const badges = badgesWrapper.querySelectorAll('.js-profile-badge.hidden');
    trigger.addEventListener('click', () => {
      badges.forEach((badge) => {
        badge.classList.remove('hidden');
      });

      trigger.classList.add('hidden');
    });
  }
}
