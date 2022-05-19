/* global timestampToLocalDateTime InstantClick */

function initializeSettings() {
  // initialize org secret copy to clipboard functionality
  const settingsOrgSecretInput = document.getElementById('settings-org-secret');
  const settingsOrgSecretButton = document.getElementById(
    'settings-org-secret-copy-btn',
  );

  if (settingsOrgSecretInput && settingsOrgSecretButton) {
    settingsOrgSecretButton.addEventListener('click', () => {
      const { value } = settingsOrgSecretInput;
      window.Forem.Runtime.copyToClipboard(value).then(() => {
        // Show the confirmation message
        document
          .getElementById('copy-text-announcer')
          .classList.remove('hidden');
      });
    });
  }

  // shows RSS fetch time in local time
  let timeNode = document.getElementById('rss-fetch-time');
  if (timeNode) {
    var timeStamp = timeNode.getAttribute('datetime');
    var timeOptions = {
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
    };

    timeNode.textContent = timestampToLocalDateTime(
      timeStamp,
      navigator.language,
      timeOptions,
    );
  }

  const mobilePageSelector = document.getElementById('mobile-page-selector');

  if (mobilePageSelector) {
    mobilePageSelector.addEventListener('change', (event) => {
      const url = event.target.value;

      InstantClick.preload(url);
      InstantClick.display(url);
    });
  }
}
