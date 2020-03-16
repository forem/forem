const getUserStatus = () =>
  document.getElementsByTagName('body')[0].getAttribute('data-user-status');

const getNoticationData = () =>
  document.getElementById('notification-subscriptions-area').dataset;

const fetchNotificationBy = (type, id) => {
  fetch(`/notification_subscriptions/${type}/${id}`, {
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(result => {
      document
        .getElementById(`notification-subscription-label_${result.config}`)
        .classList.add('selected');
    });
};

function loadFunctionality() {
  if (!document.getElementById('notification-subscriptions-area')) {
    return;
  }

  const { notifiableId, notifiableType } = getNoticationData();

  const userStatus = getUserStatus();

  if (userStatus === 'logged-in') {
    fetchNotificationBy(notifiableType, notifiableId);
  }

  let updateStatus = () => {};

  const subscriptionButtons = document.getElementsByClassName(
    'notification-subscription-label',
  );

  if (userStatus === 'logged-out') {
    updateStatus = () => {
      // Disabled because showModal() is globally defined in asset pipeline
      // eslint-disable-next-line no-undef
      showModal('notification-subscription');
    };
  } else {
    updateStatus = target => {
      let payload = '';
      const shouldUnsubscribeToNotifications = el =>
        el.classList.contains('selected') ||
        el.classList.contains('selected-emoji');

      subscriptionButtons.forEach(el => el.classList.remove('selected'));

      if (shouldUnsubscribeToNotifications) {
        const unsubscribeButton = subscriptionButtons.namedItem('unsubscribe');
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
        }),
      });
    };
  }

  const handleClick = e => {
    e.preventDefault();
    updateStatus(e.target);
    if (typeof window.sendHapticMessage !== 'undefined') {
      window.sendHapticMessage('medium');
    }
  };

  const handleKeydown = e => {
    if (e.key === 'Enter') {
      updateStatus(e.target);
    }
  };

  subscriptionButtons.forEach(element => {
    element.addEventListener('click', handleClick);
    element.addEventListener('keydown', handleKeydown);
  });
}

window.InstantClick.on('change', () => {
  loadFunctionality();
});

loadFunctionality();
