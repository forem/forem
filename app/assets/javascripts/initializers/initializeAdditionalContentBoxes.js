function initializeAdditionalContentBoxes() {
  var el = document.getElementById('additional-content-area');
  if (el) {
    var d = new Date();
    var signature = d
      .getTime()
      .toString()
      .substring(0, 5);
    var user = userData();
    var stateParam = 'include_sponsors';
    if (user && !user.display_sponsors) {
      stateParam = 'do_not_include_sponsors';
    }
    window
      .fetch(
        '/additional_content_boxes?article_id=' +
          el.dataset.articleId +
          '&signature=' +
          signature +
          '&state=' +
          stateParam,
        {
          method: 'GET',
          credentials: 'same-origin',
        },
      )
      .then(function(response) {
        if (response.status === 200) {
          response.text().then(function(html) {
            el.innerHTML = html;
            initializeReadingListIcons();
            initializeAllFollowButts();
            initializeSponsorshipVisibility();
          });
        } else {
          // there's currently no errorCb.
        }
      });
  }
}
