// import { getInstantClick } from '../topNavigation/utilities';
// import { locale } from '@utilities/locale';

/* global showModalAfterError*/

function addButtonSubscribeText(button, config) {
  let label = '';
  let pressed = '';
  switch (config) {
    case 'all_comments':
      label = `Subscribed to comments`;
      pressed = 'true';
      break;
    case 'top_level_comments':
      label = `Subscribed to top comments`;
      pressed = 'true';
      break;
    case 'author_comments':
      label = `Subscribed to author comments`;
      pressed = 'true';
      break;
    default:
      label = `Subscribe to comments`;
      pressed = 'false';
  }
  button.setAttribute('aria-label', label);
  button.querySelector('span').innerText = label;
  pressed.length === 0
    ? button.removeAttribute('aria-pressed')
    : button.setAttribute('aria-pressed', pressed);
}

function optimisticallyUpdateButtonUI(button) {
  const { info } = button.dataset;
  const buttonInfo = JSON.parse(info);
  if (buttonInfo) {
    const { config } = buttonInfo;

    switch (config) {
      case 'all_comments':
      case 'top_level_comments':
      case 'author_comments':
        button.classList.remove('reacted');
        button.querySelector('span').innerText = 'Subscribe to comments';
        break;
      default:
        button.classList.add('reacted');
        addButtonSubscribeText(button, 'all_comments');
    }
  } else {
    button.classList.add('reacted');
    addButtonSubscribeText(button, 'all_comments');
    return;
  }

  return;
}

function handleSubscribeButtonClick({ target }) {
  optimisticallyUpdateButtonUI(target);

  let payload;
  if (JSON.parse(target.dataset.info)) {
    const { id } = JSON.parse(target.dataset.info);
    payload = JSON.stringify({
      comment: {
        notification_id: id,
        comment_id: Number(target.dataset.comment),
      },
    });
  } else {
    payload = JSON.stringify({
      comment: {
        notification_id: null,
        comment_id: Number(target.dataset.comment),
      },
    });
  }
  getCsrfToken()
    .then(sendFetch('comment-subscribe', payload))
    .then((response) => {
      if (response.status !== 200) {
        showModalAfterError({
          response,
          element: 'comment',
          action_ing: 'subscribing',
          action_past: 'subscribed',
          timeframe: 'for a day',
        });
      }
    });
}

function initializeSubscribeButton() {
  const buttons = document.querySelectorAll('.subscribe-button');

  if (buttons.length === 0) {
    return;
  }

  Array.from(buttons, (button) => {
    const buttonInfo = JSON.parse(button.dataset.info);

    if (buttonInfo) {
      const { config } = buttonInfo;

      addButtonSubscribeText(button, config);
    } else {
      addButtonSubscribeText(button, '');
    }
  });
}

function listenForSubscribeButtonClicks() {
  document
    .querySelector('.subscribe-button')
    .addEventListener('click', handleSubscribeButtonClick);
}

initializeSubscribeButton();
listenForSubscribeButtonClicks();
// Some follow buttons are added to the DOM dynamically, e.g. search results,
// So we listen for any new additions to be fetched
// const observer = new MutationObserver((mutationsList) => {
//   mutationsList.forEach((mutation) => {
//     if (mutation.type === 'childList') {
//       initializeSubscribeButton()
//     }
//   });
// });

// Any element containing the given data-attribute will be monitored for new follow buttons
// document
//   .querySelectorAll('[data-subscribe-button-container]')
//   .forEach((subscribeButtonContainer) => {
//     observer.observe(subscribeButtonContainer, {
//       childList: true,
//       subtree: true,
//     });
//   });

// getInstantClick().then((ic) => {
//   ic.on('change', () => {
//     observer.disconnect();
//   });
// });

// window.addEventListener('beforeunload', () => {
//   observer.disconnect();
// });
