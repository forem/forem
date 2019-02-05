// finds all elements with chat action button class
function initializeAllChatButtons() {
  var chatButtons = document.getElementsByClassName('chat-action-button');
  var i;
  for (i = 0; i < chatButtons.length; i += 1) {
    initializeChatButton(chatButtons[i]);
  }
}

function initializeChatButton(button) {
  // if user logged out, do nothing
  var userStatus = document
    .getElementsByTagName('body')[0]
    .getAttribute('data-user-status');
  var user = userData();
  var buttonInfo = JSON.parse(button.dataset.info);

  if (userStatus === 'logged-out' || user.id === buttonInfo.id || button.dataset.fetched === 'fetched') {
    return;
  }
  fetchButton(button, buttonInfo);
}

function fetchButton(button, buttonInfo) {
  button.dataset.fetched = 'fetched'; // telling initialize that this button has been fetched
  var dataRequester;
  if (window.XMLHttpRequest) {
      dataRequester = new XMLHttpRequest();
  } else {
      dataRequester = new ActiveXObject('Microsoft.XMLHTTP');
  }
  dataRequester.onreadystatechange = function() {
    if (dataRequester.readyState === XMLHttpRequest.DONE && dataRequester.status === 200) {
      addButtonClickHandle(dataRequester.response, button);
    }
  }
  dataRequester.open('GET', '/follows/' + buttonInfo.id + '?followable_type=' + buttonInfo.className);
  dataRequester.send();
}

function addButtonClickHandle(response, button) {
  // currently lacking error handling
  assignInitialButtonResponse(response, button);
  button.onclick = function() {
    handleOptimisticButtonRender(button);
  }
}

function assignInitialButtonResponse(response, button) {
  button.classList.add('showing');
  if (response === 'mutual' || JSON.parse(button.dataset.info).showChat === "open") {
    button.style.display = 'initial'; // show button
    assignChatState(button);
  }
}

function handleOptimisticButtonRender(button) {
  try {
    var eventFabUserId = JSON.parse(button.dataset.info).id;
    document.querySelectorAll('.chat-action-button').forEach(function(fab) {
      try {
        if (fab.dataset.info) {
          var fabUserId = JSON.parse(fab.dataset.info).id;
          if (fabUserId && fabUserId === eventFabUserId) {
            assignChatState(fab);
          }
        }
      } catch (err) {}
    });
  } catch (err) {
    return;
  }
  handleChatButtonPress(button);
}

function handleChatButtonPress(button) {
  var buttonDataInfo = JSON.parse(button.dataset.info);
  var formData = new FormData();
  formData.append('user_id', buttonDataInfo.id);
  formData.append('controller', 'users');
  getCsrfToken()
    .then(sendFetch('chat-creation', formData))
    .then(() => {
      window.location.href = `/connect/@${buttonDataInfo.username}`;
    });
}

function assignChatState(button) {
  var style = '';
  if (button.dataset.info) {
    style = JSON.parse(button.dataset.info).style;
  }
  button.innerHTML = 'CHAT';
}
