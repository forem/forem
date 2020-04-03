import {
  handleLoggedOut,
  observeForReplyClick,
  prepareOpenButton,
} from '../responseTemplates/responseTemplates';

const { userStatus } = document.body.dataset;

const form = document.getElementById('new_comment');

window.InstantClick.on('change', () => {
  if (userStatus === 'logged-out') {
    handleLoggedOut();
  } else {
    if (form) {
      prepareOpenButton(form);
    }
    observeForReplyClick();
  }
});

if (userStatus === 'logged-out') {
  handleLoggedOut();
} else {
  if (form) {
    prepareOpenButton(form);
  }
  observeForReplyClick();
}
