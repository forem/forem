'use strict';

/* global timestampToLocalDateTime */

function initializeSettings() {
  // highlights organization secret on click
  const settingsOrgSecret = document.getElementById('settings-org-secret');
  if (settingsOrgSecret) {
    settingsOrgSecret.addEventListener('click', event => {
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

  // asks for confirmation on activating pro membership
  const createProForm = document.getElementById('new_pro_membership');
  if (createProForm) {
    createProForm.addEventListener('submit', event => {
      event.preventDefault();

      // eslint-disable-next-line no-alert
      if (window.confirm('Are you sure?')) {
        event.target.submit();
        return true;
      }

      return false;
    });
  }
}
