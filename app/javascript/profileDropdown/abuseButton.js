export default function initAbuseButton() {
  const abuseButton = document.getElementById(
    'user-profile-dropdownmenu-abuse-button',
  );
  if (!abuseButton) {
    // button not always present when this is called
    return;
  }

  const { profileUserId } = abuseButton.dataset;

  function flagAsAbusive() {
    fetch(`/reactions`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        reactable_id: profileUserId,
        category: 'vomit',
        reactable_type: 'User',
      }),
    })
      .then(response => response.json())
      .then(response => {
        if (response.result === 'create') {
          abuseButton.innerText = 'Remove Abuse Flag';
        } else if (response.result === 'destroy') {
          abuseButton.innerText = 'Flag as Abusive';
        }
      })
      .catch(e => {
        // eslint-disable-next-line no-alert
        window.alert(
          `Something went wrong: ${e}. -- Please refresh the page to try again.`,
        );
      });
  }

  abuseButton.addEventListener('click', flagAsAbusive);
}
