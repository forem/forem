function initModal() {
  var modal = document.querySelector('.modal');
  modal.querySelector('.close-modal').addEventListener('click', toggleModal);
  modal.querySelector('.overlay').addEventListener('click', toggleModal);
}

function toggleModal() {
  var modal = document.querySelector('.modal');
  var currentState = modal.style.display;

  if (currentState === 'none') {
    showChatModal(modal);
  } else {
    hideChatModal(modal);
  }
}

function showChatModal(modal) {
  modal.style.display = 'block';
  document.getElementById('new-message').focus();
}

function hideChatModal(modal) {
  modal.style.display = 'none';
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
  var linkWrap = document.getElementById("user-connect-redirect");
  var form = document.getElementById('new-message-form');
  button.classList.add('showing');
  if (modalInfo.showChat === "open" && response !== "mutual") {
    linkWrap.removeAttribute("href") // remove link
    button.addEventListener('click', toggleModal);
    button.style.display = 'initial'; // show button
    linkWrap.style.display = 'initial'; // show button
    form.onsubmit = function() {handleChatButtonPress(form); return false;};
  } else if (response === 'mutual') {
    button.removeEventListener('click', toggleModal);
    button.style.display = 'initial'; // show button
    linkWrap.style.display = 'initial'; // show button
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
  dataRequester.onreadystatechange = function() {
    if (dataRequester.readyState === XMLHttpRequest.DONE && dataRequester.status === 200) {
      addButtonClickHandle(dataRequester.response, button, modalInfo);
    }
  }
  dataRequester.open('GET', '/follows/' + modalInfo.id + '?followable_type=' + modalInfo.className);
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
