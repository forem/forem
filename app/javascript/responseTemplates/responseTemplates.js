/* eslint-disable no-alert */
/* eslint-disable no-restricted-globals */

export function toggleTemplateTypeButton(e) {
  const targetType = e.target.dataset.type; // moderator
  const activeType = targetType === 'personal' ? 'moderator' : 'personal';
  // don't use document for comment replies
  e.target.classList.toggle('active');
  document.querySelector(`.${activeType}-template-button`).classList.toggle('active');
  document.querySelector(`.${targetType}-responses-container`).classList.toggle('hidden');
  document.querySelector(`.${activeType}-responses-container`).classList.toggle('hidden');
}

function buildResponseTemplateHTML(response, typeOf) {
  if (response.length === 0 && typeOf === 'personal_comment') {
    return `
<div class="mod-response-wrapper mod-response-wrapper-empty">
  <p>🤔... It looks like you don't have any templates yet.</p>
  <p>Create templates to quickly answer FAQs or store snippets for re-use.</p>
</div>
`;
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
    return response.map((obj) => {
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
        window.location = response.path;
      }
    });
}

function addClickListeners(responsesWrapper, commentReplyId) {
  const form = commentReplyId
    ? document.querySelector(`form#new-comment-${commentReplyId}`)
    : document.querySelector('form#new_comment');
  const parentCommentId = form.id !== 'new_comment'
    ? form.querySelector('input#comment_parent_id').value
    : null;
  const insertButtons = Array.from(
    responsesWrapper.getElementsByClassName('insert-template-button'),
  );
  const moderatorSubmitButtons = Array.from(
    responsesWrapper.getElementsByClassName('moderator-submit-button'),
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
        responsesWrapper.parentElement.classList.toggle('hidden');
      }
    });
  });

  moderatorSubmitButtons.forEach((button) => {
    button.addEventListener('click', (e) => {
      e.preventDefault();

      const confirmMsg = `
Are you sure you want to submit this comment as Sloan?

It will be sent immediately and users will be notified.

Make sure this is the appropriate comment for the situation.

This action is not reversible.`;
      if (confirm(confirmMsg)) {
        submitAsModerator(e.target.dataset.responseTemplateId, parentCommentId);
        responsesWrapper.parentElement.classList.toggle('hidden');
      }
    });
  });
}

export function addToggleListener(responsesWrapper) {
  const toggleButton = document.querySelector('.response-templates-button');

  toggleButton.addEventListener('click', () => {
    responsesWrapper.classList.toggle('hidden');
  });
}

export function fetchResponseTemplates(typeOf) {
  // const responsesData = document.querySelector('#response-templates-data');
  let dataContainer;
  if (typeOf === 'personal_comment') {
    dataContainer = document.querySelector('.personal-responses-container');
  } else if (typeOf === 'mod_comment') {
    dataContainer = document.querySelector('.moderator-responses-container');
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
      document.querySelector('img.loading-img').classList.toggle('hidden');
      dataContainer.innerHTML = buildResponseTemplateHTML(response, typeOf);
      addClickListeners(dataContainer);
      // if (responsesWrapper) {
      //   responsesWrapper.innerHTML = dataContainer.innerHTML;
      //   addClickListeners(responsesWrapper);
      // }
    });
}

export function addReplyObservers() {
  const targetNodes = Array.from(
    document.querySelectorAll('div.comment-submit-actions.actions'),
  );
  const config = { attributes: false, childList: true, characterData: false };
  const containerWithData = document.getElementById('response-templates-data');

  const callback = (mutationsList) => {
    const { target } = mutationsList[0];
    if (mutationsList[0].addedNodes.length === 1) {
      const button = target.querySelector('button.response-templates-button');
      const responsesWrapper = target.querySelector(
        '.response-templates-container',
      );
      if (containerWithData.innerHTML === '') {
        fetchResponseTemplates(containerWithData, responsesWrapper);
        responsesWrapper.innerHTML = containerWithData.innerHTML;
      }

      if (containerWithData.innerHTML !== '') {
        responsesWrapper.innerHTML = containerWithData.innerHTML;
        addClickListeners(responsesWrapper);
      }

      button.addEventListener('click', () => {
        if (responsesWrapper.style.display === 'none') {
          responsesWrapper.style.display = 'flex';
        } else {
          responsesWrapper.style.display = 'none';
        }
      });
    }
  };

  const observer = new MutationObserver(callback);

  targetNodes.forEach((node) => {
    observer.observe(node, config);
  });

  window.addEventListener('beforeunload', () => {
    observer.disconnect();
  });

  window.InstantClick.on('change', () => {
    observer.disconnect();
  });
}

export function handleLoggedOut() {
  const toggleButton = document.querySelector('.response-templates-button');
  // global method from app/assets/javascripts/utilities/showModal.js
  /* eslint-disable-next-line no-undef */
  toggleButton.addEventListener('click', showModal);
}
/* eslint-enable no-alert */
/* eslint-enable no-restricted-globals */
