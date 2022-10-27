import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';
import {
  closeWindowModal,
  showWindowModal,
  WINDOW_MODAL_ID,
} from '@utilities/showModal';
/* global userData  */

function toggleSubscribeActionUI({
  tagContainer,
  showSubscribeAction = false,
  appleAuth = false,
}) {
  const signedInUI = tagContainer.getElementsByClassName(
    'ltag__user-subscription-tag__signed-in',
  )[0];

  const appleAuthUI = tagContainer.getElementsByClassName(
    'ltag__user-subscription-tag__apple-auth',
  )[0];

  if (!showSubscribeAction) {
    appleAuthUI.classList.add('hidden');
    signedInUI.classList.add('hidden');
    return;
  }

  // In this case we don't have an email we can use, and need the user to update their settings first
  if (appleAuth) {
    signedInUI.classList.add('hidden');
    appleAuthUI.classList.remove('hidden');
    return;
  }

  signedInUI.classList.remove('hidden');
}

function toggleSignedOutUI(tagContainer, showSignedOutUI = false) {
  const signedOutUI = tagContainer.getElementsByClassName(
    'ltag__user-subscription-tag__signed-out',
  )[0];
  if (showSignedOutUI) {
    signedOutUI.classList.remove('hidden');
  } else {
    signedOutUI.classList.add('hidden');
  }
}

function updateProfileImagesUI(tagContainer, signedIn = false) {
  const profileImagesContainer = tagContainer.getElementsByClassName(
    'ltag__user-subscription-tag__profile-images',
  )[0];

  if (signedIn) {
    profileImagesContainer.classList.add('signed-in');
    profileImagesContainer.classList.remove('signed-out');

    tagContainer
      .getElementsByClassName(
        'ltag__user-subscription-tag__subscriber-profile-image',
      )[0]
      .classList.remove('hidden');
  } else {
    profileImagesContainer.classList.remove('signed-in');
    profileImagesContainer.classList.add('signed-out');

    tagContainer
      .getElementsByClassName(
        'ltag__user-subscription-tag__subscriber-profile-image',
      )[0]
      .classList.add('hidden');
  }
}

function initSignedOutState(tagContainer) {
  toggleSubscribeActionUI({ tagContainer, showSubscribeAction: false });
  toggleSignedOutUI(tagContainer, true);
  updateProfileImagesUI(tagContainer, false);
}

function initSignedInState(tagContainer, appleAuth = false) {
  toggleSubscribeActionUI({
    tagContainer,
    showSubscribeAction: true,
    appleAuth,
  });
  toggleSignedOutUI(tagContainer, false);
  updateProfileImagesUI(tagContainer, true);

  tagContainer
    .querySelector('.ltag__user-subscription-tag__signed-in .crayons-btn')
    .addEventListener('click', () => {
      showConfirmSubscribeModal();
    });
}

function showConfirmSubscribeModal() {
  showWindowModal({
    title: 'Confirm subscribe',
    size: 'small',
    modalContent: document.querySelector(
      '.user-subscription-confirmation-modal .crayons-modal__box__body',
    ).innerHTML,
    onOpen: () => {
      // Attach listeners for cancel button and subscribe button
      document
        .querySelector(
          `#${WINDOW_MODAL_ID} .ltag__user-subscription-tag____cancel-btn`,
        )
        .addEventListener('click', () => {
          closeWindowModal();
        });

      document
        .querySelector(
          `#${WINDOW_MODAL_ID} .ltag__user-subscription-tag__confirmation-btn`,
        )
        .addEventListener('click', confirmSubscribe);
    },
  });
}

function confirmSubscribe() {
  closeWindowModal();
  clearNotices();

  submitSubscription().then((response) => {
    if (response.success) {
      const allSubscriptionLiquidTags = document.getElementsByClassName(
        'ltag__user-subscription-tag',
      );

      showSubscribedNotices();

      for (const tagContainer of allSubscriptionLiquidTags) {
        // We no longer want to show the submit button since user is now subscribed
        toggleSubscribeActionUI({ tagContainer, showSubscribeAction: false });
      }
    } else {
      updateNotices({ variant: 'danger', content: response.error });
      // Allow user to retry
      toggleSubmitButtonsState({ disabled: false, textContent: 'Subscribe' });
    }
  });
}

function toggleSubmitButtonsState({ disabled, textContent }) {
  // Since all user sub tags on the same article page perform the same action, all submit buttons are kept in sync
  const allUserSubLiquidTagSubmits = document.querySelectorAll(
    '.ltag__user-subscription-tag__signed-in .crayons-btn',
  );

  for (const submit of allUserSubLiquidTagSubmits) {
    submit.disabled = disabled;
    submit.textContent = textContent;
  }
}

function updateNotices({ variant, content }) {
  const allNotices = document.getElementsByClassName(
    'ltag__user-subscription-tag__response-message',
  );

  for (const notice of allNotices) {
    notice.classList.remove('hidden');
    notice.classList.add(`crayons-notice--${variant}`);
    notice.textContent = content;
  }

  // When a notice is shown, we hide the generic signed-in instructions
  toggleSignedInInstructionsUI(false);
}

function clearNotices() {
  // Since all user sub tags on the same article page perform the same action, all notices are kept in sync
  const allNotices = document.getElementsByClassName(
    'ltag__user-subscription-tag__response-message',
  );

  for (const notice of allNotices) {
    notice.classList.add('hidden');
  }

  // Re-show the signed in instructions
  toggleSignedInInstructionsUI(true);
}

function toggleSignedInInstructionsUI(isVisible) {
  const signedInInstructions = document.querySelectorAll(
    '.ltag__user-subscription-tag__signed-in .ltag__user-subscription-tag__logged-in-text',
  );

  for (const instructions of signedInInstructions) {
    if (isVisible) {
      instructions.classList.remove('hidden');
    } else {
      instructions.classList.add('hidden');
    }
  }
}

function submitSubscription() {
  toggleSubmitButtonsState({ disabled: true, textContent: 'Submitting' });

  const articleId =
    document.getElementById('article-body')?.dataset?.articleId ?? null;

  const subscriber = userData();
  const body = JSON.stringify({
    user_subscription: {
      source_type: 'Article',
      source_id: articleId,
      subscriber_email: subscriber.email,
    },
  });

  return getCsrfToken()
    .then(sendFetch('user_subscriptions', body))
    .then((res) => res.json());
}

function fetchSubscriptionStatus() {
  const { articleId } = document.getElementById('article-body').dataset;

  const params = new URLSearchParams({
    source_type: 'Article',
    source_id: articleId,
  }).toString();

  const headers = {
    Accept: 'application/json',
    'X-CSRF-Token': window.csrfToken,
    'Content-Type': 'application/json',
  };

  return fetch(`/user_subscriptions/subscribed?${params}`, {
    method: 'GET',
    headers,
    credentials: 'same-origin',
  }).then((response) => {
    if (response.ok) {
      return response.json();
    }
    console.error(
      `Base data error: ${response.status} - ${response.statusText}`,
    );
  });
}

function showSubscribedNotices() {
  const { authorUsername } = document.getElementsByClassName(
    'ltag__user-subscription-tag',
  )[0].dataset;

  updateNotices({
    variant: 'success',
    content: `You are now subscribed and may receive emails from ${authorUsername}`,
  });
}

function populateSubscriberProfileImage({
  profile_image_90: profileImageSrc,
  username,
}) {
  document
    .querySelectorAll('.ltag__user-subscription-tag__subscriber-profile-image')
    .forEach((profileImage) => {
      profileImage.src = profileImageSrc;
      profileImage.alt = username;
    });
}

/**
 * Initializes the functionality of any user_subscription liquid tags in an article.
 *
 * An article may have more than one user_subscription liquid tag, but all instances complete the same action,
 * and are therefore kept in-step throughout any user interaction or update (i.e. the UI and behavior of all user_subscription
 * liquid tags in an article will always be the same).
 */
export async function initializeUserSubscriptionLiquidTagContent() {
  const allUserSubLiquidTags = document.getElementsByClassName(
    'ltag__user-subscription-tag__container',
  );

  const { userStatus } = document.querySelector('body').dataset;
  if (userStatus === 'logged-out') {
    for (const liquidTag of allUserSubLiquidTags) {
      initSignedOutState(liquidTag);
    }
    return;
  }

  const { currentUser: user } = await getUserDataAndCsrfToken();
  const { apple_auth: isSubscriberAuthedWithApple } = user;

  // Setup the initial signed-in state without waiting on subscription status fetch
  for (const liquidTag of allUserSubLiquidTags) {
    initSignedInState(liquidTag, isSubscriberAuthedWithApple);
  }

  // Check if we need to refresh UI due to existing subscription
  populateSubscriberProfileImage(user);
  fetchSubscriptionStatus().then(({ is_subscribed: isSubscribed }) => {
    if (isSubscribed) {
      showSubscribedNotices();
    }
    for (const liquidTag of allUserSubLiquidTags) {
      toggleSubscribeActionUI({
        tagContainer: liquidTag,
        showSubscribeAction: !isSubscribed,
        appleAuth: isSubscriberAuthedWithApple,
      });
    }
  });
}
