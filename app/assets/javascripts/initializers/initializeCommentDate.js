/* Show comment date/time according to user's locale */
/* global timestampToLocalDateTime */

function initializeCommentDate() {
  // example: "Wednesday, April 3, 2019, 2:55:14 PM"
  var hoverTimeOptions = {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
  };

  // example: "Apr 3"
  var visibleDateOptions = {
    month: 'short',
    day: 'numeric',
  };

  var commentDates = document.getElementsByClassName('comment-date');
  for (var i = 0; i < commentDates.length; i += 1) {
    // get UTC timestamp set by the server
    var ts = commentDates[i].getAttribute('data-published-timestamp');

    // add a full datetime to the comment date string, visible on hover
    // `navigator.language` is used for full date times to allow the hover date
    // to be localized according to the user's locale
    var hoverTime = timestampToLocalDateTime(
      ts,
      navigator.language,
      hoverTimeOptions,
    );
    commentDates[i].setAttribute('title', hoverTime);

    // replace the comment short visible date with the equivalent localized one
    var visibleDate = commentDates[i].querySelector('a');
    if (visibleDate) {
      var localVisibleDate = timestampToLocalDateTime(
        ts,
        'en-US', // en-US because for now we want all users to see `Apr 3`
        visibleDateOptions,
      );
      if (localVisibleDate) {
        visibleDate.innerHTML = localVisibleDate;
      }
    }
  }
}
