/* global timestampToLocalDateTime */

function initializeSettings() {
  if (document.getElementById('settings-org-secret')) {
    document.getElementById('settings-org-secret').onclick = function(event) {
      event.target.select();
    };
  }

  if (document.getElementById('rss-fetch-time')) {
    var timeNode = document.getElementById('rss-fetch-time');
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
}
