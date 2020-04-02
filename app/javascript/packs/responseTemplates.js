import { handleLoggedOut, fetchResponseTemplates, addReplyObservers, addToggleListener, toggleTemplateTypeButton } from '../responseTemplates/responseTemplates';

const { userStatus } = document.body.dataset;

function prepareOpenButton() {
  const button = document.querySelector('.response-templates-button')
  if (!button) {
    return
  }

  button.addEventListener('click', () => {
    const responsesContainer = document.querySelector('.response-templates-container');
    const personalTemplateButton = document.querySelector('.personal-template-button');
    const modTemplateButton = document.querySelector('.moderator-template-button');
    const loadingImg = document.querySelector('img.loading-img')
    responsesContainer.classList.toggle('hidden');
    loadingImg.classList.toggle('hidden')

    fetchResponseTemplates('personal_comment');
    addToggleListener(responsesContainer);
    /* eslint-disable-next-line no-undef */
    if (userData().moderator_for_tags.length > 0) {
      personalTemplateButton.addEventListener('click', toggleTemplateTypeButton)
      modTemplateButton.addEventListener('click', toggleTemplateTypeButton)
      modTemplateButton.classList.remove('hidden')
      modTemplateButton.addEventListener('click', () => {
        loadingImg.classList.toggle('hidden')
        fetchResponseTemplates('mod_comment')
      }, { once: true });
    }
  }, { once: true });
}

window.InstantClick.on('change', () => {
  if (userStatus === 'logged-out') {
    handleLoggedOut();
  } else {
    prepareOpenButton();
  }
});

if (userStatus === 'logged-out') {
  handleLoggedOut();
} else {
  prepareOpenButton();
  addReplyObservers();
}
