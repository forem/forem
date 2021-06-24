'use strict';

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
