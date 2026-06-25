import { initializeDropdown } from '@utilities/dropdownUtils';

const ARTICLE_ID_REGEX = /\/(\d+)$/;
const ARTICLE_FORM_KEY_REGEX = /\[(.*)\]/;

function getFormValues(form) {
  const articleId = form.action.match(ARTICLE_ID_REGEX)[1];
  const inputs = form.getElementsByTagName('input');
  const formData = { id: articleId, article: {} };

  for (let i = 0; i < inputs.length; i++) {
    const input = inputs[i];
    const name = input.getAttribute('name');
    const value = input.getAttribute('value');

    const articleFormKeyMatches = name.match(ARTICLE_FORM_KEY_REGEX);
    if (articleFormKeyMatches) {
      const key = articleFormKeyMatches[1];
      formData.article[key] = value;
    } else {
      formData[name] = value;
    }
  }

  return formData;
}

function onXhrSuccess() {
  window.location.reload();
}

const handleFormSubmit = (e) => {
  e.preventDefault();
  e.stopPropagation();

  const { target: form } = e;
  const values = getFormValues(form);
  const data = JSON.stringify(values);

  const formData = new FormData(form);
  const method = formData.get('_method') || 'post';

  const xhr = new XMLHttpRequest();
  xhr.open(method.toUpperCase(), form.action);
  xhr.setRequestHeader('Content-Type', 'application/json');
  xhr.send(data);

  xhr.onload = function onload() {
    const article = form.closest('.js-dashboard-story');

    const messageContainer = article.querySelector(
      '.js-dashboard-story-details',
    );

    if (xhr.status === 200) {
      onXhrSuccess();
      const message =
        values.commit === 'Mute Notifications'
          ? 'Notifications Muted'
          : 'Notifications Restored';

      if (messageContainer) {
        messageContainer.innerHTML = message;
      }
    } else if (messageContainer) {
      messageContainer.innerHTML = 'Failed to update article.';
    }
  };
};

const initializeArchiveToggleFormSubmit = () => {
  const archiveToggleForms = document.querySelectorAll(
    '.js-ellipsis-menu-dropdown .js-archive-toggle',
  );

  archiveToggleForms.forEach((form) => {
    form.addEventListener('submit', handleFormSubmit);
  });
};

const initializeEllipsisMenuToggle = () => {
  const dropdownTriggerButtons = document.querySelectorAll(
    'button[id^=ellipsis-menu-trigger-]',
  );

  dropdownTriggerButtons.forEach((triggerButton) => {
    if (triggerButton.dataset.initialized !== 'true') {
      const dropdownContentId = triggerButton.getAttribute('aria-controls');
      const { closeDropdown } = initializeDropdown({
        triggerElementId: triggerButton.id,
        dropdownContentId,
      });

      // Close dropdown after toggling the archive status
      document
        .getElementById(dropdownContentId)
        ?.querySelectorAll('.js-archive-toggle')
        ?.forEach((menuElement) => {
          menuElement.addEventListener('click', closeDropdown);
        });
      triggerButton.dataset.initialized = 'true';
    }
  });
};

initializeEllipsisMenuToggle();
initializeArchiveToggleFormSubmit();
