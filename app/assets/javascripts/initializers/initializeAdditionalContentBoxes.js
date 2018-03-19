function initializeAdditionalContentBoxes() {
  var el = document.getElementById("additional-content-area");
  if (el) {
    window.fetch('/additional_content_boxes?article_id='+el.dataset.articleId, {
          method: 'GET',
          credentials: 'same-origin'
        }).then(function (response) {
      if (response.status === 200) {
        response.text().then(function(html){
          el.innerHTML = html;
          initializeReadingListIcons();
          initializeAllFollowButts();
          initializeSponsorshipVisibility();
        })
      } else {
        // there's currently no errorCb.
      }
    });
  }
}