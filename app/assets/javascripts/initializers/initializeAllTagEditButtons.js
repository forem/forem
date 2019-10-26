'use strict';

function initializeAllTagEditButtons() {
  var tagEditButton = document.getElementById('tag-edit-button');
  var user = userData();
  if (
    user &&
    tagEditButton &&
    user.moderator_for_tags.indexOf(tagEditButton.dataset.tag) > -1
  ) {
    tagEditButton.style.display = 'inline-block';
    document.getElementById('tag-mod-button').style.display = 'inline-block';
  }
}
