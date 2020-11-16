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
          var reportAbuseLink = profileDropdownDiv.querySelector(
            '.report-abuse-link-wrapper',
          );
          reportAbuseLink.innerHTML = `<a href="${reportAbuseLink.dataset.path}" class="crayons-link crayons-link--block">Report Abuse</a>`;
        });
      }
    }
  }
}

function initializeProfileInfoToggle() {
  const infoPanels = document.querySelector('.js-user-info');
  const trigger = document.querySelector('.js-user-info-trigger');
  const triggerWrapper = document.querySelector(
    '.js-user-info-trigger-wrapper',
  );

  if (trigger && infoPanels) {
    trigger.addEventListener('click', () => {
      triggerWrapper.classList.replace('block', 'hidden');
      infoPanels.classList.replace('hidden', 'grid');
    });
  }
}

function initializeProfileBadgesToggle() {
  const badgesWrapper = document.querySelector('.js-profile-badges');
  const trigger = document.querySelector('.js-profile-badges-trigger');

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
