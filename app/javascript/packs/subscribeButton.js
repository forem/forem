// /* global showModalAfterError*/

export function addButtonSubscribeText(button, config) {
  let label = '';
  let pressed = '';
  let mobileLabel = '';
  const noun =
    button.dataset.comment && button.dataset.ancestry ? 'thread' : 'comments';

  // Find the <span> element within the button
  const spanElement = button.querySelector('span');

  switch (config) {
    case 'all_comments':
      label = `Subscribed to ${noun}`;
      mobileLabel = `${noun}`.charAt(0).toUpperCase() + noun.slice(1);
      pressed = 'true';
      break;
    case 'top_level_comments':
      label = `Subscribed to top-level comments`;
      mobileLabel = `Top-level ${noun}`;
      pressed = 'true';
      break;
    case 'only_author_comments':
      label = `Subscribed to author comments`;
      mobileLabel = `Author ${noun}`;
      pressed = 'true';
      break;
    default:
      label = `Subscribe to ${noun}`;
      mobileLabel = `${noun}`.charAt(0).toUpperCase() + noun.slice(1);
      pressed = 'false';
  }

  button.setAttribute('aria-label', label);
  spanElement.innerText = window.innerWidth <= 760 ? mobileLabel : label;
  button.setAttribute('aria-pressed', pressed);
}

export function optimisticallyUpdateButtonUI(button) {
  const buttonInfo = button.dataset.info
    ? JSON.parse(button.dataset.info)
    : null;
  if (buttonInfo) {
    const { config } = buttonInfo;

    switch (config) {
      case 'all_comments':
      case 'top_level_comments':
      case 'only_author_comments':
        button.classList.remove('comment-subscribed');
        addButtonSubscribeText(button, '');
        break;
      default:
        button.classList.add('comment-subscribed');
        addButtonSubscribeText(button, 'all_comments');
    }
  } else {
    button.classList.add('comment-subscribed');
    addButtonSubscribeText(button, 'all_comments');
    return;
  }

  return;
}

async function handleSubscribeButtonClick({ target }) {
  optimisticallyUpdateButtonUI(target);

  let payload;
  let endpoint;
  if (JSON.parse(target.dataset.info)) {
    const { id } = JSON.parse(target.dataset.info);
    payload = JSON.stringify({
      comment: {
        action: 'unsubscribe',
        subscription_id: id,
      },
    });
    endpoint = 'comment-unsubscribe';
  } else {
    payload = JSON.stringify({
      comment: {
        action: 'subscribe',
        subscription_id: null,
        comment_id: Number(target.dataset.comment),
        article_id: target.dataset.article
          ? Number(target.dataset.article)
          : null,
      },
    });
    endpoint = 'comment-subscribe';
  }

  getCsrfToken()
    .then(await sendFetch(endpoint, payload))
    .then(async (response) => {
      if (response.status === 200) {
        const res = await response.json();
        console.log(res); // eslint-disable-line no-console
        if (res.notification) {
          target.dataset.info = res.notification;
        } else if (res.destroyed) {
          target.dataset.info = null;
        } else {
          target.dataset.info = null;
        }
      } else {
        // showModalAfterError({
        //   response,
        //   element: 'comment',
        //   action_ing: 'subscribing',
        //   action_past: 'subscribed',
        //   timeframe: 'for a day',
        // });
      }
    });
}

export function initializeSubscribeButton() {
  const buttons = document.querySelectorAll('.subscribe-button');

  if (buttons.length === 0) {
    return;
  }

  Array.from(buttons, (button) => {
    button.removeEventListener('click', handleSubscribeButtonClick); // Remove previous event listener
    button.addEventListener('click', handleSubscribeButtonClick);

    const buttonInfo = button.dataset.info
      ? JSON.parse(button.dataset.info)
      : null;

    if (buttonInfo) {
      const { config } = buttonInfo;
      addButtonSubscribeText(button, config);
    } else {
      addButtonSubscribeText(button, '');
    }
  });
}

initializeSubscribeButton();

// Some subscribe buttons are added to the DOM dynamically.
// So we listen for any new additions to be fetched
const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      initializeSubscribeButton();
    }
  });
});

// Any element containing the given data-attribute will be monitored for new follow buttons
document
  .querySelectorAll('[data-subscribe-button-container]')
  .forEach((subscribeButtonContainer) => {
    observer.observe(subscribeButtonContainer, {
      childList: true,
      attributes: true,
    });
  });

window.addEventListener('beforeunload', () => {
  observer.disconnect();
});
