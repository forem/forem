/* global timestampToLocalDateTime InstantClick */

function initializeSettings() {
  // highlights organization secret on click
  const settingsOrgSecret = document.getElementById('settings-org-secret');
  if (settingsOrgSecret) {
    settingsOrgSecret.addEventListener('click', (event) => {
      event.target.select();
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
