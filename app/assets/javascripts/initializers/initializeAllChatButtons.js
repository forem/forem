// finds all elements with chat action button class
function initializeAllChatButtons() {
  var chatForms = document.getElementsByClassName('chat-action-form');
  var i;
  for (i = 0; i < chatForms.length; i += 1) {
    initializeChatButton(chatForms[i]);
  }
}

function initializeChatButton(form) {
  // if user logged out, do nothing
  var user = userData();
  var formInfo = JSON.parse(form.dataset.info);
  if (user === null || user.id === formInfo.id || form.dataset.fetched === 'fetched') {
    return;
  }
  fetchButton(form, formInfo);
}

function fetchButton(form, formInfo) {
  var dataRequester;
  form.dataset.fetched = 'fetched'; // telling initialize that this button has been fetched
  if (window.XMLHttpRequest) {
      dataRequester = new XMLHttpRequest();
  } else {
      dataRequester = new ActiveXObject('Microsoft.XMLHTTP');
  }
  dataRequester.onreadystatechange = function() {
    if (dataRequester.readyState === XMLHttpRequest.DONE && dataRequester.status === 200) {
      addButtonClickHandle(dataRequester.response, form);
    }
  }
  dataRequester.open('GET', '/follows/' + formInfo.id + '?followable_type=' + formInfo.className);
  dataRequester.send();
}

function addButtonClickHandle(response, form) {
  // currently lacking error handling
  form.classList.add('showing');
  if (JSON.parse(form.dataset.info).showChat === "open") {
    form.onsubmit = function() {return handleChatButtonPress(form);}; // only adds function call if chat is open
    form.style.display = 'initial'; // show form
  } else if (response === 'mutual') {
    form.style.display = 'initial'; // show form
  }
}

function handleChatButtonPress(form) {
  var formDataInfo = JSON.parse(form.dataset.info);
  var formData = new FormData();
  formData.append('user_id', formDataInfo.id);
  formData.append('controller', 'chat_channels');
  console.log(formData)
  getCsrfToken()
    .then(sendFetch('chat-creation', formData));
}
