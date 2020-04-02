import { handleLoggedOut, observeForReplyClick } from '../responseTemplates/responseTemplates';

const { userStatus } = document.body.dataset;

window.InstantClick.on('change', () => {
  if (userStatus === 'logged-out') {
    handleLoggedOut();
  } else {
   observeForReplyClick();
  }
});

if (userStatus === 'logged-out') {
  handleLoggedOut();
} else {
 observeForReplyClick();
}
