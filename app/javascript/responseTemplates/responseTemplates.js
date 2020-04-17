/* eslint-disable no-alert */
/* eslint-disable no-restricted-globals */

function toggleTemplateTypeButton(form, e) {
  const { targetType } = e.target.dataset;
  const activeType = targetType === 'personal' ? 'moderator' : 'personal';
  e.target.classList.toggle('active');
  form
    .querySelector(`.${activeType}-template-button`)
    .classList.toggle('active');
  form
    .querySelector(`.${targetType}-responses-container`)
    .classList.toggle('hidden');
  form
    .querySelector(`.${activeType}-responses-container`)
    .classList.toggle('hidden');
}

const noResponsesHTML = `
<div class="mod-response-wrapper mod-response-wrapper-empty">
  <p>🤔... It looks like you don't have any templates yet.</p>
  <p>Create templates to quickly answer FAQs or store snippets for re-use.</p>
</div>
`;

function buildHTML(response, typeOf) {
  if (response.length === 0 && typeOf === 'personal_comment') {
    return noResponsesHTML;
  }
  if (typeOf === 'personal_comment') {
    return response
      .map((obj) => {
        return `
          <div class="mod-response-wrapper">
            <span>${obj.title}</span>
            <p>${obj.content}</p>
            <button class="insert-template-button" type="button" data-content="${obj.content}">INSERT</button>
          </div>
        `;
      })
      .join('');
  }
  if (typeOf === 'mod_comment') {
    return response
      .map((obj) => {
        return `
            <div class="mod-response-wrapper">
              <span>${obj.title}</span>
              <p>${obj.content}</p>
              <button class="insert-template-button" type="button" data-content="${obj.content}">INSERT</button>
              <button class="moderator-submit-button" type="submit" data-response-template-id="${obj.id}">SEND AS MOD</button>
            </div>
          `;
      })
      .join('');
  }
  return `Error 😞`;
}

function submitAsModerator(responseTemplateId, parentId) {
  const commentableId = document.querySelector('input#comment_commentable_id')
    .value;

  fetch(`/comments/moderator_create`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      response_template: {
        id: responseTemplateId,
      },
      comment: {
        body_markdown: '',
        commentable_id: commentableId,
        commentable_type: 'Article',
        parent_id: parentId,
      },
    }),
  })
    .then((response) => response.json())
    .then((response) => {
      if (response.status === 'created') {
        window.location.pathname = response.path;
      } else if (response.status === 'comment already exists') {
        alert('This comment already exists.');
      } else if (response.error === 'error') {
        alert(
          `There was a problem submitting this comment: ${response.status}`,
        );
      }
    });
}

const confirmMsg = `
Are you sure you want to submit this comment as Sloan?

It will be sent immediately and users will be notified.

Make sure this is the appropriate comment for the situation.

This action is not reversible.`;

function addClickListeners(form) {
  const responsesContainer = form.querySelector(
    '.response-templates-container',
  );
  const parentCommentId =
    form.id !== 'new_comment'
      ? form.querySelector('input#comment_parent_id').value
      : null;
  const insertButtons = Array.from(
    responsesContainer.getElementsByClassName('insert-template-button'),
  );
  const moderatorSubmitButtons = Array.from(
    responsesContainer.getElementsByClassName('moderator-submit-button'),
  );

  insertButtons.forEach((button) => {
    button.addEventListener('click', (e) => {
      const { content } = e.target.dataset;
      const textArea = form.querySelector('textarea');
      const textAreaReplaceable =
        textArea.value === null ||
        textArea.value === '' ||
        confirm('Are you sure you want to replace your current comment draft?');

      if (textAreaReplaceable) {
        textArea.value = content;
        responsesContainer.classList.toggle('hidden');
      }
    });
  });

  moderatorSubmitButtons.forEach((button) => {
    button.addEventListener('click', (e) => {
      e.preventDefault();

      if (confirm(confirmMsg)) {
        submitAsModerator(e.target.dataset.responseTemplateId, parentCommentId);
      }
    });
  });
}

function fetchResponseTemplates(typeOf, formId) {
  const form = document.getElementById(formId);
  let dataContainer;
  if (typeOf === 'personal_comment') {
    dataContainer = form.querySelector('.personal-responses-container');
  } else if (typeOf === 'mod_comment') {
    dataContainer = form.querySelector('.moderator-responses-container');
  }
  /* eslint-disable-next-line no-undef */
  fetch(`/response_templates?type_of=${typeOf}`, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
  })
    .then((response) => response.json())
    .then((response) => {
      form.querySelector('img.loading-img').classList.toggle('hidden');
      dataContainer.innerHTML = buildHTML(response, typeOf);
      const topLevelData = document.getElementById('response-templates-data');
      topLevelData.innerHTML = dataContainer.parentElement.innerHTML;
      addClickListeners(form);
    });
}

function prepareHeaderButtons(form) {
  const personalTemplateButton = form.querySelector(
    '.personal-template-button',
  );
  const modTemplateButton = form.querySelector('.moderator-template-button');

  personalTemplateButton.addEventListener('click', (e) => {
    toggleTemplateTypeButton(form, e);
  });
  modTemplateButton.addEventListener('click', (e) => {
    toggleTemplateTypeButton(form, e);
  });
  modTemplateButton.classList.remove('hidden');

  modTemplateButton.addEventListener(
    'click',
    () => {
      const topLevelData = document.getElementById('response-templates-data');
      const modDataNotFetched =
        topLevelData.innerHTML !== ''
          ? topLevelData.querySelector('.moderator-responses-container')
              .childElementCount === 0
          : false;
      if (modDataNotFetched) {
        form.querySelector('img.loading-img').classList.toggle('hidden');
        fetchResponseTemplates('mod_comment', form.id);
      }
    },
    { once: true },
  );
}

function copyData(responsesContainer) {
  responsesContainer.innerHTML = document.getElementById(
    'response-templates-data',
  ).innerHTML;
}

function loadData(form) {
  form.querySelector('img.loading-img').classList.toggle('hidden');
  fetchResponseTemplates('personal_comment', form.id);
}

function openButtonCallback(form) {
  const responsesContainer = form.querySelector(
    '.response-templates-container',
  );
  const dataFetched =
    document.getElementById('response-templates-data').innerHTML !== '';

  responsesContainer.classList.toggle('hidden');

  const containerHidden = responsesContainer.classList.contains('hidden');

  if (dataFetched && !containerHidden) {
    copyData(responsesContainer);
    addClickListeners(form);
  } else if (!dataFetched && !containerHidden) {
    loadData(form)
  }
  /* eslint-disable-next-line no-undef */
  if (userData().moderator_for_tags.length > 0) {
    prepareHeaderButtons(form);
  } else {
    form.querySelector('.personal-template-button').classList.add('hidden');
  }
}

function prepareOpenButton(form) {
  const button = form.querySelector('.response-templates-button');
  if (!button) {
    return;
  }

  button.addEventListener('click', () => {
    openButtonCallback(form);
  });

  button.dataset.hasListener = "true";
}

function observeForReplyClick() {
  const config = { childList: true, subtree: true };

  const callback = (mutations) => {
    const form = mutations[0].addedNodes[0];
    if (form.nodeName === 'FORM') {
      prepareOpenButton(form);
    }
  };

  const observer = new MutationObserver(callback);

  const commentTree = document.getElementById('comment-trees-container');
  observer.observe(commentTree, config);

  window.addEventListener('beforeunload', () => {
    observer.disconnect();
  });

  window.InstantClick.on('change', () => {
    observer.disconnect();
  });
}

function handleLoggedOut() {
  const toggleButton = document.querySelector('.response-templates-button');
  // global method from app/assets/javascripts/utilities/showModal.js
  /* eslint-disable-next-line no-undef */
  toggleButton.addEventListener('click', showModal);
}
/* eslint-enable no-alert */
/* eslint-enable no-restricted-globals */

export function loadResponseTemplates() {
  const { userStatus } = document.body.dataset;
  const form = document.getElementById('new_comment');

  if (document.getElementById('response-templates-data')) {
    if (userStatus === 'logged-out') {
      handleLoggedOut();
    }
    if (
      form &&
      form.querySelector('.response-templates-button').dataset.hasListener === 'false'
    ) {
      prepareOpenButton(form);
    }
    observeForReplyClick();
  }
}
