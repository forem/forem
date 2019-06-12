const label = document.getElementById('notification-subscription-label')
const checkbox = document.getElementById('notification-subcription-checkbox')
const subscriptionStatusInput = document.getElementById('notification-subscription-status')
const notifiableId = document.getElementById('notification-subscription-notifiable-id').value
const notifiableType = document.getElementById('notification-subscription-notifiable-type').value

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
  .then((result) => {
    subscriptionStatusInput.value = result
    checkbox.checked = result
  })

const handleClick = (e) => {
  e.preventDefault()
  
  checkbox.checked = !checkbox.checked
  
  fetch(`/notification_subscriptions/${notifiableType}/${notifiableId}`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
    body: JSON.stringify({
      subscription_status: subscriptionStatusInput.value
    })
  })
    .then(response => response.json())
    .then((result) => {
      subscriptionStatusInput.value = result
      checkbox.checked = result
    })
}


label.addEventListener("click", handleClick)
checkbox.addEventListener("click", handleClick)
