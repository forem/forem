export function sendFollowUser(user, successCb) {
  const csrfToken = document.querySelector("meta[name='csrf-token']").content;

  const formData = new FormData();
  formData.append('followable_type', 'User');
  formData.append('followable_id', user.id);
  formData.append('verb', user.following ? 'unfollow' : 'follow');

  fetch('/follows', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken,
    },
    body: formData,
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((json) => {
      successCb(json.outcome);
      // json is followed or unfollowed
    })
    .catch((error) => {
      // TODO: Add client-side error tracking. See https://github.com/thepracticaldev/dev.to/issues/2501
      // for the discussion.
      console.log(error); // eslint-disable-line no-console
    });
}
