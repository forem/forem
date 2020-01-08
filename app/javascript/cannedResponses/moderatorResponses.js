/* eslint-disable no-alert */
/* eslint-disable no-restricted-globals */
export default function initModeratorResponses() {
  function submitAsModerator(content) {
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
        comment: {
          body_markdown: content,
          commentable_id: commentableId,
          commentable_type: 'Article',
        },
      }),
    })
      .then(response => response.json())
      .then(response => {
        if (response.status === 'created') {
          /* eslint-disable-next-line no-restricted-globals */
          window.location.reload();
          // or maybe try to build the reply?
        }
      });
  }

  function addClickListeners() {
    const selfSubmitButtons = Array.from(
      document.getElementsByClassName('mod-response-button'),
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
          submitAsModerator(e.target.dataset.content);
        }
      });
    });
  }

  function fetchCannedResponses() {
    const responsesWrapper = document.querySelector('.mod-responses-container');

    fetch(`/canned_responses?type_of=mod_comment`, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': window.csrfToken,
      },
    })
      .then(response => response.json())
      .then(response => {
        const toggleButton = document.querySelector('.canned-responses-button');
        const innerHTML = response
          .map(obj => {
            return `
            <div class="mod-response-wrapper">
              <span>${obj.title}</span>
              <p>${obj.contentTruncated50}</p>
              <button class="mod-response-button" type="button" data-content="${obj.content}">USE TEMPLATE</button>
              <button class="moderator-submit-button" type="submit" data-content="${obj.content}">SUBMIT AS MOD</button>
            </div>
          `;
          })
          .join('');

        responsesWrapper.innerHTML = innerHTML;

        addClickListeners();

        toggleButton.addEventListener('click', () => {
          if (responsesWrapper.style.display === 'none') {
            responsesWrapper.style.display = 'flex';
          } else {
            responsesWrapper.style.display = 'none';
          }
        });
      });
  }

  fetchCannedResponses();
}
/* eslint-enable no-alert */
/* eslint-enable no-restricted-globals */
