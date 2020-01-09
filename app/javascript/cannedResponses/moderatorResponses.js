/* eslint-disable no-alert */
/* eslint-disable no-restricted-globals */
export default function initModeratorResponses() {
  function submitAsModerator(cannedResponseId) {
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

  function addClickListeners() {
    const selfSubmitButtons = Array.from(
      document.getElementsByClassName('mod-template-button'),
    );
    const moderatorSubmitButtons = Array.from(
      document.getElementsByClassName('moderator-submit-button'),
    );
    const textArea = document.querySelector('#text-area'); // make this work for replies

    selfSubmitButtons.forEach(button => {
      button.addEventListener('click', e => {
        const responsesWrapper = document.querySelector(
          '.mod-responses-container',
        );
        const { content } = e.target.dataset;

        textArea.value = content;
        responsesWrapper.style.display = 'none';
      });
    });

    moderatorSubmitButtons.forEach(button => {
      button.addEventListener('click', e => {
        e.preventDefault();

        if (confirm('Are you sure you want to submit a comment under Sloan?')) {
          submitAsModerator(e.target.dataset.cannedResponseId);
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
        `;

        addToggleListener(responsesWrapper);
        addClickListeners();
      });
  }

  fetchCannedResponses();
}
/* eslint-enable no-alert */
/* eslint-enable no-restricted-globals */
