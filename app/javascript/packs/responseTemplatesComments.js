import { handleLoggedOut, addReplyObservers } from '../responseTemplates/responseTemplates';

const userStatus = document.querySelector('body').getAttribute('data-user-status');

window.InstantClick.on('change', () => {
  if (userStatus === 'logged-out') {
    handleLoggedOut();
  } else {
    addReplyObservers();
  }
});

if (userStatus === 'logged-out') {
  handleLoggedOut();
} else {
  addReplyObservers();
}
