/* eslint-disable no-use-before-define */
/* eslint-disable no-undef */
/* eslint-disable func-names */
/* eslint-disable consistent-return */
/* eslint-disable no-unused-vars */

function initializeReadingListIcons() {
  setReadingListButtonsState();
  addReadingListCountToHomePage();
  addHoverEffectToReadingListButtons();
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
}

function addReadingListCountToHomePage() {
  var user = userData();
  var readingListCount;
  if (user && document.getElementById('reading-list-count')) {
    readingListCount =
      user.reading_list_ids.length > 0 ? user.reading_list_ids.length : '';
    document.getElementById('reading-list-count').innerHTML = readingListCount;
    document.getElementById('reading-list-count').dataset.count =
      user.reading_list_ids.length;
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
    addHoverEffectToReadingListButtons(button);
  } else {
    button.classList.remove('selected');
  }
}

function renderNewSidebarCount(button, json) {
  var newCount;
  var count = document.getElementById('reading-list-count').dataset.count;
  count = parseInt(count, 10);
  if (json.result === 'create') {
    newCount = count + 1;
  } else if (count !== 0) {
    newCount = count - 1;
  }
  document.getElementById('reading-list-count').dataset.count = newCount;
  document.getElementById('reading-list-count').innerHTML =
    newCount > 0 ? newCount : '';
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
  Add the hover effect to reading list buttons.

  This function makes use of mouseover/mouseevent bubbling behaviors to attach
  only two event handlers to the articles container for performance reasons.
*/
function addHoverEffectToReadingListButtons() {
  var articlesList = document.getElementsByClassName('articles-list');
  Array.from(articlesList).forEach(function (container) {
    // we use `bind` so that the event handler will have the correct text in its
    // `this` local variable
    container.addEventListener(
      'mouseover',
      readingListButtonMouseHandler.bind('Unsave'),
    );
    container.addEventListener(
      'mouseout',
      readingListButtonMouseHandler.bind('Saved'),
    );
  });
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
