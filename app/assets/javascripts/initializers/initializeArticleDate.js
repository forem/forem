/* Show article date/time according to user's locale */
/* global addLocalizedDateTimeToElementsTitles */

function initializeArticleDate() {
  var articlesDates = document.querySelectorAll(
    '.single-article time, article time, .single-other-article time',
  );

  addLocalizedDateTimeToElementsTitles(articlesDates, 'datetime');
}
