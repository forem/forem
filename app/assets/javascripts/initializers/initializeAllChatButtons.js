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

  if (userStatus === 'logged-out') {
    return;
  }

  // don't show chat button when looking at own profile
  if (user.id === buttonInfo.id) {
    
  } else if (
    // check if users follow each other, or if user has inbox type as open
    (user.followed_user_ids.includes(buttonInfo.id) &&
      buttonInfo.userFollowing.includes(user.id)) ||
    buttonInfo.showChat === 'open'
  ) {
    button.style.display = 'initial'; // show button
    if (button.dataset.fetched === 'fetched') {
      return;
    }
    fetchButton(button);
  }
}

function fetchButton(button) {
  button.dataset.fetched = 'fetched'; // telling initialize that this button has been fetched
  assignChatState(button);
  button.onclick = () => {
    handleOptimisticButtonRender(button);
  };
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
  getCsrfToken().then(sendFetch('chat-creation', formData));
  window.location.href = `/connect/@${buttonDataInfo.username}`;
}

function assignChatState(button) {
  var style = '';
  if (button.dataset.info) {
    style = JSON.parse(button.dataset.info).style;
  }
  button.innerHTML = 'CHAT';
}
