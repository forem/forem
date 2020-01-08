/* eslint-disable no-alert */
/* eslint-disable no-restricted-globals */
export default function initCannedResponses() {
  function prepareHTML(dropdownContent, response) {
    const newDropdownContent = dropdownContent;
    const newCannedResponseLink = `<a href="/settings/canned-responses" class="canned-response-dropbtn" target="_blank" rel="noopener">
        + New Response
      </a>
      `;

    if (response.length === 0) {
      newDropdownContent.innerHTML = newCannedResponseLink;
    } else {
      const innerHTMLText = response.map(obj => {
        return `
        <button type="button" class="canned-response-dropbtn" data-title="${obj.title}" data-form-id="" data-content="${obj.content}">
          <span class="title">${obj.titleTruncated}</span>
          <span class="content">${obj.contentTruncated}</span>
        </button>`;
      });

      innerHTMLText.push(newCannedResponseLink);
      newDropdownContent.innerHTML = innerHTMLText.join('');
    }
  }

  function addEventListenersToButtons() {
    const buttons = Array.from(
      document.querySelectorAll('button.canned-response-dropbtn'),
    );
    buttons.forEach(button => {
      // change this to handle replies

      button.addEventListener('click', () => {
        const newCommentField = document.querySelector('textarea#text-area');
        const { title, content } = button.dataset;
        const confirmMsg = `Are you sure you want to use this canned response: "${title}"?`;

        if (confirm(confirmMsg)) {
          newCommentField.value = content;
        }
      });
    });
  }

  function fetchCannedResponses() {
    const dropdownContent = document.querySelector(
      '.editor-canned-responses>.dropdown>.dropdown-content',
    );
    fetch(`/canned_responses`, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': window.csrfToken,
      },
    })
      .then(response => response.json())
      .then(response => {
        prepareHTML(dropdownContent, response);
        addEventListenersToButtons();
      });
    // do more things maybe
  }

  fetchCannedResponses();
}
/* eslint-enable no-alert */
/* eslint-enable no-restricted-globals */
