/* Show comment date/time according to user's locale */
/* global timestampToLocalTime */

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
  var visibileTimeOptions = {
    month: 'short',
    day: 'numeric',
  };

  var commentDates = document.getElementsByClassName('comment-date');
  for (var i = 0; i < commentDates.length; i += 1) {
    // get UTC timestamp set by the server
    var ts = commentDates[i].getAttribute('data-published-timestamp');

    // add a full datetime to the comment date string, visible on hover
    var hoverTime = timestampToLocalTime(ts, hoverTimeOptions);
    commentDates[i].setAttribute('title', hoverTime);

    // replace the comment short visible date with the equivalent localized one
    var visibleDate = commentDates[i].querySelector('a');
    if (visibleDate) {
      var localTime = timestampToLocalTime(ts, visibileTimeOptions);
      if (localTime) {
        visibleDate.innerHTML = localTime;
      }
    }
  }
}
