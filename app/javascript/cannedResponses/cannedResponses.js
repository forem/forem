/* eslint-disable no-alert */
/* eslint-disable no-restricted-globals */
export default function initCannedResponses() {
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

        const confirmMsg = `
Are you sure you want to submit this comment as Sloan?

It will be sent immediately and users will be notified.

Make sure this is the appropriate comment for the situation.

This action is not reversible.`;
        if (confirm(confirmMsg)) {
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

    window.addEventListener('beforeunload', () => {
      observer.disconnect();
    });

    window.InstantClick.on('change', () => {
      observer.disconnect();
    });
  }

  function buildModResponseHTML(response) {
    const array = response
      .filter(obj => {
        return obj.type_of === 'mod_comment';
      })
      .map(obj => {
        return `
              <div class="mod-response-wrapper">
                <span>${obj.title}</span>
                <p>${obj.content}</p>
                <button class="mod-template-button" type="button" data-content="${obj.content}">INSERT</button>
                <button class="moderator-submit-button" type="submit" data-canned-response-id="${obj.id}">SEND AS MOD</button>
              </div>
              `;
      });

    array.unshift('<header><h3>Mod Responses</h3></header>')
    return array.join('');
  }

  function fetchCannedResponses() {
    const responsesWrapper = document.querySelector('.mod-responses-container');
    /* eslint-disable-next-line no-undef */
    const moderatorForTags = userData().moderator_for_tags;
    const url =
      moderatorForTags.length === 0
        ? '/canned_responses'
        : '/canned_responses?type_of=mod_comment&personal_included=true';

    fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
    })
      .then(response => response.json())
      .then(response => {
        const modResponseHTML =
          moderatorForTags.length === 0 ? '' : buildModResponseHTML(response);
        let personalResponseHTML = response
          .filter(obj => {
            return obj.type_of === 'personal_comment';
          })
          .map(obj => {
            return `
              <div class="mod-response-wrapper">
                <span>${obj.title}</span>
                <p>${obj.content}</p>
                <button class="mod-template-button" type="button" data-content="${obj.content}">INSERT</button>
              </div>
            `;
          })
          .join('');
          if (personalResponseHTML.length === 0) {
          personalResponseHTML = `<div class="mod-response-wrapper mod-response-wrapper-empty">
                                    <p>🤔... It looks like you don't have any templates yet.</p>
                                    <p>Create templates to quickly answer FAQs or store snippets for re-use.</p>
                                  </div>`
        }
        responsesWrapper.innerHTML = `
          ${modResponseHTML}
          <header><h3>Personal Templates</h3></header>
          ${personalResponseHTML}
          <a target="_blank" rel="noopener nofollow" href="/settings/canned-responses" class="mod-respons-create-new">Create new template</a>
        `;

        addToggleListener(responsesWrapper);
        addClickListeners(responsesWrapper);
        addReplyObservers();
      });
  }

  function handleLoggedOut() {
    const toggleButton = document.querySelector('.canned-responses-button');
    // see showModal.js
    /* eslint-disable-next-line no-undef */
    toggleButton.addEventListener('click', showModal);
  }

  const userStatus = document.querySelector('body').getAttribute('data-user-status');
  if (userStatus === 'logged-out') {
    handleLoggedOut();
  } else {
    fetchCannedResponses();
  }
}
/* eslint-enable no-alert */
/* eslint-enable no-restricted-globals */
