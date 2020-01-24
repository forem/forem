import loadingImg from '../../assets/images/loading-ellipsis.svg'
import { handleLoggedOut, fetchResponseTemplates, addReplyObservers, addToggleListener } from '../responseTemplates/responseTemplates';

const userStatus = document.querySelector('body').getAttribute('data-user-status');

function prepareButton() {
  const button = document.querySelector('.response-templates-button')

  button.addEventListener('click', () => {
    const responsesWrapper = document.querySelector('.mod-responses-container');
    responsesWrapper.style.display = 'flex';
    responsesWrapper.innerHTML = `<img class="loading-img" src=${loadingImg} alt="loading">`

    fetchResponseTemplates(responsesWrapper, responsesWrapper);
    addToggleListener(responsesWrapper);
  }, { once: true });
}

window.InstantClick.on('change', () => {
  if (userStatus === 'logged-out') {
    handleLoggedOut();
  } else {
    prepareButton();
  }
});

if (userStatus === 'logged-out') {
  handleLoggedOut();
} else {
  prepareButton();
  addReplyObservers();
}
