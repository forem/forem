const label = document.getElementById('notification-subscription-label');
const checkbox = document.getElementById('notification-subcription-checkbox');
const subscriptionStatusInput = document.getElementById(
  'notification-subscription-status',
);
const notifiableId = document.getElementById(
  'notification-subscription-notifiable-id',
).value;
const notifiableType = document.getElementById(
  'notification-subscription-notifiable-type',
).value;
const userStatus = document
  .getElementsByTagName('body')[0]
  .getAttribute('data-user-status');

// do a check for signed out users
// check if showModal() function is defined (probably not necessary b/c of defer)

fetch(`/notification_subscriptions/${notifiableType}/${notifiableId}`, {
  headers: {
    Accept: 'application/json',
    'X-CSRF-Token': window.csrfToken,
    'Content-Type': 'application/json',
  },
  credentials: 'same-origin',
})
  .then(response => response.json())
  .then(result => {
    subscriptionStatusInput.value = result;
    checkbox.checked = result;
  });

let updateStatus = () => {};

if (userStatus === 'logged-out') {
  updateStatus = () => {
    // Disabled because showModal() is globally defined in asset pipeline
    // eslint-disable-next-line no-undef
    showModal('notification-subscription');
  };
} else {
  updateStatus = () => {
    const originalSubscriptionStatusValue = subscriptionStatusInput.value;
    checkbox.checked = !checkbox.checked;

    fetch(`/notification_subscriptions/${notifiableType}/${notifiableId}`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
      body: JSON.stringify({
        currently_subscribed: subscriptionStatusInput.value,
        // notifiable params are passed via URL
      }),
    })
      .then(response => response.json())
      .then(result => {
        if (result === 'Subscription rate limit reached') {
          label.firstChild.data = result;
          checkbox.checked = !checkbox.checked;
          subscriptionStatusInput.value = originalSubscriptionStatusValue;

          label.classList.remove('enabled');
          label.classList.add('disabled');

          setTimeout(() => {
            label.firstChild.data = 'Subscribe to Notifications';
            label.classList.remove('disabled');
            label.classList.add('enabled');
          }, 30000);
        } else {
          subscriptionStatusInput.value = result;
          checkbox.checked = result;

          label.classList.remove('enabled');
          label.classList.add('disabled');

          setTimeout(() => {
            label.classList.remove('disabled');
            label.classList.add('enabled');
          }, 1500);
        }
      });
  };
}

label.addEventListener('click', e => {
  e.preventDefault();
  updateStatus();
});
checkbox.addEventListener('click', e => {
  e.preventDefault();
  updateStatus();
});

checkbox.addEventListener('keydown', e => {
  if (e.key === 'Enter') {
    updateStatus();
  }
});
