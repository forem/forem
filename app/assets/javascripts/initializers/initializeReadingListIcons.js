/* eslint-disable no-use-before-define */
/* eslint-disable no-undef */
/* eslint-disable func-names */
/* eslint-disable consistent-return */
/* eslint-disable no-unused-vars */

function initializeReadingListIcons() {
  setReadingListButtonsState();
  addReadingListCountToHomePage();
}

// set SAVE or SAVED articles buttons
function setReadingListButtonsState() {
  var readingListButtons = document.querySelectorAll(
    '.bookmark-button:not([data-initial-feed])',
  );
  Array.from(readingListButtons).forEach(highlightButton);
}

// private

function highlightButton(button) {
  var user = userData();
  var buttonIdInt = parseInt(button.dataset.reactableId, 10);
  if (user && user.reading_list_ids.indexOf(buttonIdInt) > -1) {
    button.classList.add('selected');
  } else {
    button.classList.remove('selected');
  }
  button.addEventListener('click', reactToReadingListButtonClick);
  button.dataset.saveInitialized = true;
}

function addReadingListCountToHomePage() {
  const user = userData();
  const readingListContainers = document.querySelectorAll(
    '.js-reading-list-count',
  );
  if (user && readingListContainers) {
    readingListContainers.forEach(function (e) {
      const readingListCount =
        user.reading_list_ids.length > 0 ? user.reading_list_ids.length : '';
      e.innerHTML = readingListCount;
      e.dataset.count = user.reading_list_ids.length;
    });
  }
}

function reactToReadingListButtonClick(event) {
  var button;
  var userStatus;
  event.preventDefault();
  sendHapticMessage('medium');
  userStatus = document.body.getAttribute('data-user-status');
  if (userStatus === 'logged-out') {
    showLoginModal();
    return;
  }
  button = properButtonFromEvent(event);
  renderOptimisticResult(button);
  getCsrfToken()
    .then(sendFetch('reaction-creation', buttonFormData(button)))
    .then(function (response) {
      if (response.status === 200) {
        return response.json().then(function (json) {
          renderButtonState(button, json);
          renderNewSidebarCount(button, json);
        });
      } // else {
      // there's currently no errorCb.
      // }
    })
    .catch(function (error) {
      // there's currently no error handling.
    });
}

function renderButtonState(button, json) {
  if (json.result === 'create') {
    button.classList.add('selected');
  } else {
    button.classList.remove('selected');
  }
}

function renderNewSidebarCount(button, json) {
  const readingListContainers = document.querySelectorAll(
    '.js-reading-list-count',
  );
  if (readingListContainers) {
    readingListContainers.forEach(function (e) {
      const count = parseInt(e.dataset.count, 10);
      let newCount;
      if (json.result === 'create') {
        newCount = count + 1;
      } else if (count !== 0) {
        newCount = count - 1;
      }
      e.dataset.count = newCount;
      e.innerHTML = newCount > 0 ? newCount : '';
    });
  }
}

function buttonFormData(button) {
  var formData = new FormData();
  formData.append('reactable_type', 'Article');
  formData.append('reactable_id', button.dataset.reactableId);
  formData.append('category', 'readinglist');
  return formData;
}

function renderOptimisticResult(button) {
  renderButtonState(button, { result: 'create' }); // optimistic create only for now
}

function properButtonFromEvent(event) {
  var properElement;
  if (event.target.tagName === 'BUTTON') {
    properElement = event.target;
  } else {
    properElement = event.target.parentElement;
  }
  return properElement;
}

/*
  Determines if the element is the target of the reading list button hover.
*/
function isReadingListButtonHoverTarget(element) {
  var classList = element.classList;

  return (
    (element.tagName === 'BUTTON' &&
      classList.contains('bookmark-button') &&
      classList.contains('selected')) ||
    (element.tagName === 'SPAN' && classList.contains('bm-success'))
  );
}

function readingListButtonMouseHandler(event) {
  var target = event.target;

  if (isReadingListButtonHoverTarget(target)) {
    event.preventDefault();

    var textReplacement = this; // `this` is the text to be replaced
    var textSpan;
    if (target.tagName === 'BUTTON') {
      textSpan = target.getElementsByClassName('bm-success')[0];
    } else {
      textSpan = target;
    }

    textSpan.innerHTML = textReplacement;
  }
}

/* eslint-enable no-use-before-define */
/* eslint-enable no-undef */
/* eslint-enable func-names */
/* eslint-enable consistent-return */
/* eslint-enable no-unused-vars */
