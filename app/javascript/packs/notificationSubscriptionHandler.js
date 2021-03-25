/* global showLoginModal */

function loadFunctionality() {
  if (!document.getElementById('notification-subscriptions-area')) {
    return;
  }
  const { notifiableId } = document.getElementById(
    'notification-subscriptions-area',
  ).dataset;
  const { notifiableType } = document.getElementById(
    'notification-subscriptions-area',
  ).dataset;

  const userStatus = document.body.getAttribute('data-user-status');

  if (userStatus === 'logged-in') {
    fetch(`/notification_subscriptions/${notifiableType}/${notifiableId}`, {
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then((response) => response.json())
      .then((result) => {
        document
          .getElementById(`notification-subscription-label_${result.config}`)
          .classList.add('selected');
        // checkbox.checked = result;
      });
  }

  let updateStatus = () => {};

  if (userStatus === 'logged-out') {
    updateStatus = () => {
      showLoginModal();
    };
  } else {
    updateStatus = (target) => {
      let payload = '';
      const shouldUnsubscribeToNotifications =
        target.classList.contains('selected') ||
        target.classList.contains('selected-emoji');
      const allButtons = document.getElementsByClassName(
        'notification-subscription-label',
      );
      for (let i = 0; i < allButtons.length; i += 1) {
        allButtons[i].classList.remove('selected');
      }
      if (shouldUnsubscribeToNotifications) {
        const unsubscribeButton = allButtons.namedItem('unsubscribe');
        unsubscribeButton.classList.add('selected');
        ({ payload } = unsubscribeButton.dataset);
      } else {
        target.classList.add('selected');
        ({ payload } = target.dataset);
      }
      fetch(`/notification_subscriptions/${notifiableType}/${notifiableId}`, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': window.csrfToken,
          'Content-Type': 'application/json',
        },
        credentials: 'same-origin',
        body: JSON.stringify({
          config: payload,
          // notifiable params are passed via URL
        }),
      });
    };
  }

  const subscriptionButtons = document.getElementsByClassName(
    'notification-subscription-label',
  );

  for (let i = 0; i < subscriptionButtons.length; i += 1) {
    subscriptionButtons[i].addEventListener('click', (e) => {
      e.preventDefault();
      updateStatus(e.target);
      if (typeof window.sendHapticMessage !== 'undefined') {
        window.sendHapticMessage('medium');
      }
    });
    subscriptionButtons[i].addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        updateStatus(e.target);
      }
    });
  }
}

window.InstantClick.on('change', () => {
  loadFunctionality();
});

loadFunctionality();
