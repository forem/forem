'use strict';

function initializeAllTagEditButtons() {
  var tagEditButton = document.getElementById('tag-edit-button');
  var tagAdminButton = document.getElementById('tag-admin-button');
  var user = userData();
  if (user.admin && tagAdminButton) {
    tagAdminButton.style.display = 'inline-block';
    document.getElementById('tag-admin-button').style.display = 'inline-block';
  }
  if (
    user &&
    tagEditButton &&
    (user.moderator_for_tags.indexOf(tagEditButton.dataset.tag) > -1 ||
      user.admin)
  ) {
    tagEditButton.style.display = 'inline-block';
    document.getElementById('tag-mod-button').style.display = 'inline-block';
  }
}
