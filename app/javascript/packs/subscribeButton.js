// /* global showModalAfterError*/

export function addButtonSubscribeText(button, config) {
  let label = '';
  let pressed = '';
  let mobileLabel = '';

  const { subscribed_to, comment_id, ancestry } = button.dataset;
  let noun = '';
  if (subscribed_to) {
    noun = (subscribed_to == 'comment') ? 'thread' : 'comments';
  } else if (comment_id && ancestry) {
    noun = 'thread'
  } else {
    noun = 'comments'
  }

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
  switch (button.dataset.subscription_mode) {
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

  return;
}

async function handleSubscribeButtonClick({ target }) {
  optimisticallyUpdateButtonUI(target);

  let payload;
  let endpoint;

  if (target.dataset.subscription_id != "") {
    payload = {
      subscription_id: target.dataset.subscription_id,
    };
    endpoint = 'comment-unsubscribe';
  } else if (target.dataset.ancestry && (target.dataset.ancestry != "")){
    payload = {
      comment_id: target.dataset.ancestry
    };
    endpoint = 'comment-subscribe';
  } else {
    payload = {
      article_id: target.dataset.article_id,
    };
    endpoint = 'comment-subscribe';
  }

  payload = JSON.stringify(payload)

  getCsrfToken()
    .then(await sendFetch(endpoint, payload))
    .then(async (response) => {
      if (response.status === 200) {
        const res = await response.json();

        if (res.destroyed) {
          target.dataset.subscription_id = "";
          target.dataset.subscription_mode = "";
        } else if (res.subscription) {
          target.dataset.subscription_id = res.subscription.id;
          target.dataset.subscription_mode = res.subscription.config;
        } else {
          throw(`Problem (un)subscribing: ${JSON.stringify(res)}`)
        }
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

    addButtonSubscribeText(button, button.dataset.subscription_mode);
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
