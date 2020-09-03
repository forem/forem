'use strict';

function showChatModal(modal) {
  // eslint-disable-next-line no-param-reassign
  modal.style.display = 'block';
  document.getElementById('new-message').focus();
}

function hideChatModal(modal) {
  // eslint-disable-next-line no-param-reassign
  modal.style.display = 'none';
}

function toggleModal() {
  var modal = document.querySelector('.crayons-modal');
  modal.classList.toggle('hidden');
}

function initModal() {
  var modal = document.querySelector('.crayons-modal');
  modal.querySelector('.close-modal').addEventListener('click', toggleModal);
  modal
    .querySelector('.crayons-modal__overlay')
    .addEventListener('click', toggleModal);
}

function handleChatButtonPress(form) {
  var message = document.getElementById('new-message').value;
  var formDataInfo = JSON.parse(form.dataset.info);
  var formData = new FormData();

  if (message.replace(/\s/g, '').length === 0) {
    return;
  }

  formData.append('user_id', formDataInfo.id);
  formData.append('message', message);
  formData.append('controller', 'chat_channels');

  getCsrfToken()
    .then(sendFetch('chat-creation', formData))
    .then(() => {
      window.location.href = `/connect/@${formDataInfo.username}`;
    });
}

function addButtonClickHandle(response, button, modalInfo) {
  var linkWrap = document.getElementById('user-connect-redirect');
  var form = document.getElementById('new-message-form');
  button.classList.add('showing');
  if (modalInfo.showChat === 'open' && response !== 'mutual') {
    linkWrap.removeAttribute('href'); // remove link
    button.addEventListener('click', toggleModal);
    // eslint-disable-next-line no-param-reassign
    button.classList.remove('hidden'); // show button
    linkWrap.classList.remove('hidden'); // show button
    form.onsubmit = () => {
      handleChatButtonPress(form);
      return false;
    };
  } else if (response === 'mutual') {
    button.removeEventListener('click', toggleModal);
    // eslint-disable-next-line no-param-reassign
    button.classList.remove('hidden'); // show button
    linkWrap.classList.remove('hidden'); // show button
  }
}

function fetchButton(button, modalInfo) {
  var dataRequester;
  // button.dataset.fetched = 'fetched'; // telling initialize that this button has been fetched
  if (window.XMLHttpRequest) {
    dataRequester = new XMLHttpRequest();
  } else {
    dataRequester = new ActiveXObject('Microsoft.XMLHTTP');
  }
  dataRequester.onreadystatechange = () => {
    if (
      dataRequester.readyState === XMLHttpRequest.DONE &&
      dataRequester.status === 200
    ) {
      addButtonClickHandle(dataRequester.response, button, modalInfo);
    }
  };
  dataRequester.open(
    'GET',
    '/follows/' + modalInfo.id + '?followable_type=' + modalInfo.className,
  );
  dataRequester.send();
}

function initializeChatButton(button, modalInfo) {
  // if user logged out, do nothing
  var user = userData();
  if (user === null || user.id === modalInfo.id) {
    return;
  }
  fetchButton(button, modalInfo);
}

// finds all elements with chat action button class
function initializeAllChatButtons() {
  var buttons = document.getElementsByClassName('chat-action-button');
  var modal = document.getElementById('new-message-form');
  var i;

  if (!modal) {
    return;
  }

  var modalInfo = JSON.parse(modal.dataset.info);
  initModal();

  for (i = 0; i < buttons.length; i += 1) {
    initializeChatButton(buttons[i], modalInfo);
  }
}
