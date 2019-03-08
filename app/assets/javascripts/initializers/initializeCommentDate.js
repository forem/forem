/* Show comment date/time according to user's locale */

function initializeCommentDate() {
  function timestampToLocalTime(timestamp) {
    if (timestamp === '') {
      return '';
    }

    var options = {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
    };

    try {
      var time = new Date(timestamp);
      return new Intl.DateTimeFormat('default', options).format(time);
    } catch (e) {
      return '';
    }
  }

  var commentDates = document.getElementsByClassName('comment-date');
  for (var i = 0; i < commentDates.length; i += 1) {
    var ts = commentDates[i].getAttribute('data-published-timestamp');
    commentDates[i].setAttribute('title', timestampToLocalTime(ts));
  }
}
