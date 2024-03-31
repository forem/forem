// /* global showModalAfterError*/

export function updateSubscribeButtonText(
  button,
  overrideSubscribed,
  window_size,
) {
  let label = '';
  let mobileLabel = '';
  if (typeof window_size == 'undefined') {
    window_size = window.innerWidth;
  }

  let noun = 'comments';
  const { subscription_id, subscription_config, comment_id } = button.dataset;

  let subscriptionIsActive = subscription_id != '';
  if (typeof overrideSubscribed != 'undefined') {
    subscriptionIsActive = overrideSubscribed == 'subscribe';
  }

  const pressed = subscriptionIsActive;
  const verb = subscriptionIsActive ? 'Subscribed' : 'Subscribe';

  // comment_id should only be present if there's a subscription, so a button
  // that initially renders as 'Subscribed-to-thread' can be a toggle until refreshed
  if (comment_id && comment_id != '') {
    noun = 'thread';
  }

  // Find the <span> element within the button
  const spanElement = button.querySelector('span');

  switch (subscription_config) {
    case 'top_level_comments':
      label = `${verb} to top-level comments`;
      mobileLabel = `Top-level ${noun}`;
      break;
    case 'only_author_comments':
      label = `${verb} to author comments`;
      mobileLabel = `Author ${noun}`;
      break;
    default:
      label = `${verb} to ${noun}`;
      mobileLabel = `${noun}`.charAt(0).toUpperCase() + noun.slice(1);
  }

  button.setAttribute('aria-label', label);
  spanElement.innerText = window_size <= 760 ? mobileLabel : label;
  button.setAttribute('aria-pressed', pressed);
}

export function optimisticallyUpdateButtonUI(button, modeChange) {
  if (typeof modeChange == 'undefined') {
    modeChange = button.dataset.subscription_id ? 'unsubscribe' : 'subscribe';
  }

  if (modeChange == 'unsubscribe') {
    button.classList.remove('comment-subscribed');
    updateSubscribeButtonText(button, 'unsubscribe');
  } else {
    button.classList.add('comment-subscribed');
    updateSubscribeButtonText(button, 'subscribe');
  }

  return;
}

export function determinePayloadAndEndpoint(button) {
  let payload;
  let endpoint;

  if (button.dataset.subscription_id != '') {
    payload = {
      subscription_id: button.dataset.subscription_id,
    };
    endpoint = 'comment-unsubscribe';
  } else if (
    button.dataset.subscribed_to &&
    button.dataset.subscribed_to == 'comment'
  ) {
    payload = {
      comment_id: button.dataset.comment_id,
    };
    endpoint = 'comment-subscribe';
  } else {
    payload = {
      article_id: button.dataset.article_id,
      subscription_config: button.dataset.subscription_config,
    };
    endpoint = 'comment-subscribe';
  }

  return {
    payload,
    endpoint,
  };
}

async function handleSubscribeButtonClick({ target }) {
  optimisticallyUpdateButtonUI(target);

  const { payload, endpoint } = determinePayloadAndEndpoint(target);
  const requestJson = JSON.stringify(payload);

  getCsrfToken()
    .then(await sendFetch(endpoint, requestJson))
    .then(async (response) => {
      if (response.status === 200) {
        const res = await response.json();

        if (res.destroyed) {
          const matchingButtons = document.querySelectorAll(
            `button[data-subscription_id='${target.dataset.subscription_id}']`,
          );
          for (let i = 0; i < matchingButtons.length; i++) {
            const button = matchingButtons[i];
            button.dataset.subscription_id = '';
            if (button != target) {
              optimisticallyUpdateButtonUI(button, 'unsubscribe');
            }
          }
        } else if (res.subscription) {
          target.dataset.subscription_id = res.subscription.id;
        } else {
          throw `Problem (un)subscribing: ${JSON.stringify(res)}`;
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
    if (button.wasInitialized) {
      return;
    }

    button.removeEventListener('click', handleSubscribeButtonClick); // Remove previous event listener
    button.addEventListener('click', handleSubscribeButtonClick);

    button.wasInitialized = true;
    updateSubscribeButtonText(button);
  });
}

// Some subscribe buttons are added to the DOM dynamically.
// They will need to call this — see initializeNotifications > initPagination
initializeSubscribeButton();
