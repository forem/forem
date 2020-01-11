/* eslint-disable no-alert */
/* eslint-disable no-restricted-globals */
export default function initModeratorResponses() {
  function submitAsModerator(cannedResponseId, parentId) {
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
        canned_response: {
          id: cannedResponseId,
        },
        comment: {
          body_markdown: '',
          commentable_id: commentableId,
          commentable_type: 'Article',
          parent_id: parentId,
        },
      }),
    })
      .then(response => response.json())
      .then(response => {
        if (response.status === 'created') {
          window.location.reload();
        }
      });
  }

  function addClickListeners(responsesWrapper) {
    const form = responsesWrapper.parentElement.parentElement;
    const parentCommentId =
      form.id !== 'new_comment'
        ? form.querySelector('input#comment_parent_id').value
        : null;
    const selfSubmitButtons = Array.from(
      responsesWrapper.getElementsByClassName('mod-template-button'),
    );
    const moderatorSubmitButtons = Array.from(
      responsesWrapper.getElementsByClassName('moderator-submit-button'),
    );

    selfSubmitButtons.forEach(button => {
      button.addEventListener('click', e => {
        const { content } = e.target.dataset;
        const textArea = form.querySelector('textarea');

        textArea.value = content;
        responsesWrapper.style.display = 'none';
      });
    });

    moderatorSubmitButtons.forEach(button => {
      button.addEventListener('click', e => {
        e.preventDefault();

        if (confirm('Are you sure you want to submit a comment under Sloan?')) {
          submitAsModerator(e.target.dataset.cannedResponseId, parentCommentId);
        }
      });
    });
  }

  function addToggleListener() {
    const responsesWrapper = document.querySelector('.mod-responses-container');
    const toggleButton = document.querySelector('.canned-responses-button');

    toggleButton.addEventListener('click', () => {
      if (responsesWrapper.style.display === 'none') {
        responsesWrapper.style.display = 'flex';
      } else {
        responsesWrapper.style.display = 'none';
      }
    });
  }

  function addReplyObservers() {
    const targetNodes = Array.from(
      document.querySelectorAll('div.comment-submit-actions.actions'),
    );
    const config = { attributes: false, childList: true, characterData: false };
    const containerWithData = document
      .getElementById('textarea-wrapper')
      .querySelector('.mod-responses-container');

    const callback = mutationsList => {
      const { target } = mutationsList[0];
      if (mutationsList[0].addedNodes.length === 1) {
        const button = target.querySelector('button.canned-responses-button');
        const responsesWrapper = target.querySelector(
          '.mod-responses-container',
        );
        responsesWrapper.innerHTML = containerWithData.innerHTML;
        addClickListeners(responsesWrapper);

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

    targetNodes.forEach(node => {
      observer.observe(node, config);
    });
  }

  function fetchCannedResponses() {
    const responsesWrapper = document.querySelector('.mod-responses-container');

    fetch(`/canned_responses?type_of=mod_comment&personal_included=true`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
    })
      .then(response => response.json())
      .then(response => {
        const modResponseHTML = response
          .filter(obj => {
            return obj.typeOf === 'mod_comment';
          })
          .map(obj => {
            return `
              <div class="mod-response-wrapper">
                <span>${obj.title}</span>
                <p>${obj.contentTruncated}</p>
                <button class="mod-template-button" type="button" data-content="${obj.content}">USE TEMPLATE</button>
                <button class="moderator-submit-button" type="submit" data-canned-response-id="${obj.id}">SUBMIT AS MOD</button>
              </div>
              `;
          })
          .join('');

        const personalResponseHTML = response
          .filter(obj => {
            return obj.typeOf === 'personal_comment';
          })
          .map(obj => {
            return `
              <div class="mod-response-wrapper">
                <span>${obj.titleTruncated}</span>
                <p>${obj.contentTruncated}</p>
                <button class="mod-template-button" type="button" data-content="${obj.content}">USE TEMPLATE</button>
              </div>
            `;
          })
          .join('');

        responsesWrapper.innerHTML = `
          <header><h3>Moderator Responses</h3></header>
          ${modResponseHTML}
          <header><h3>Personal Responses</h3></header>
          ${personalResponseHTML}
          <a target="_blank" rel="noopener nofollow" href="/settings/canned-responses">Create a new response</a>
        `;

        addToggleListener(responsesWrapper);
        addClickListeners(responsesWrapper);
        addReplyObservers();
      });
  }

  fetchCannedResponses();
}
/* eslint-enable no-alert */
/* eslint-enable no-restricted-globals */
