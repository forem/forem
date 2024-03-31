import { timestampToLocalDateTime } from '@utilities/localDateTime';

export function setupRssFetchTime() {
  // shows RSS fetch time in local time
  const timeNode = document.getElementById('rss-fetch-time');
  if (timeNode) {
    const timeStamp = timeNode.getAttribute('datetime');
    const timeOptions = {
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
