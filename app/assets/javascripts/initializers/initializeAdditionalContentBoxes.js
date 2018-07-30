function initializeAdditionalContentBoxes() {
  var el = document.getElementById("additional-content-area");
  if (el) {
    var d = new Date();
    var signature = d.getTime().toString().substring(0, 5);
    window.fetch('/additional_content_boxes?article_id='+el.dataset.articleId+'&signature='+signature, {
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