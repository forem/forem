/* Show comment date/time according to user's locale */
/* global addLocalizedDateTimeToElementsTitles */

'use strict';

function initializeCommentDate() {
  var commentsDates = document.querySelectorAll('.comment-date time');

  addLocalizedDateTimeToElementsTitles(commentsDates, 'datetime');
}
