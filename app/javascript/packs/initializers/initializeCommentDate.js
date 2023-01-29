/* Show comment date/time according to user's locale */
/* global addLocalizedDateTimeToElementsTitles */

export function initializeCommentDate() {
  console.log("Initializing CommentDate");
  const commentsDates = document.querySelectorAll('.comment-date time');

  if (commentsDates) {
    addLocalizedDateTimeToElementsTitles(commentsDates, 'datetime');
  }
}
