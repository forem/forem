export default function initBlock() {
  const blockButton = document.getElementById(
    'user-profile-dropdownmenu-block-button',
  );
  const { profileUserId } = blockButton.dataset;

  function unblock() {
    fetch(`/user_blocks/${profileUserId}`, {
      method: 'DELETE',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user_block: {
          blocked_id: profileUserId,
        },
      }),
    })
      .then(response => response.json())
      .then(response => {
        if (response.result === 'unblocked') {
          blockButton.innerText = 'Block';
          blockButton.addEventListener('click', block, { once: true });
        } else if (response.status === 422) {
          window.alert(`Something went wrong: ${e} -- Please refresh the page to try again.`)
        }
      })
      .catch(e => {
        window.alert(`Something went wrong: ${e}. -- Please refresh the page to try again.`);
      });
  }

  function block() {
    const confirmBlock = window.confirm(
      `Are you sure you want to block this person? This will:
      - prevent them from commenting on your posts
      - block all notifications from them
      - prevent them from messaging you via DEV Connect`,
    );
    if (confirmBlock) {
      fetch(`/user_blocks/${profileUserId}`, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': window.csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_block: {
            blocked_id: profileUserId,
          },
        }),
      })
        .then(response => response.json())
        .then(response => {
          if (response.result === 'blocked') {
            blockButton.innerText = 'Unblock';
            blockButton.addEventListener('click', unblock, { once: true });
          } else if (response.status === 422) {
            window.alert(`Something went wrong: ${e}. -- Please refresh the page to try again.`)
          }
        })
        .catch(e => {
          window.alert(`Something went wrong: ${e}. -- Please refresh the page to try again.`);
        });
    } else {
      blockButton.addEventListener('click', block, { once: true });
    }
  }

  // userData() is a global function
  const currentUserId = userData().id;

  if (currentUserId === parseInt(profileUserId, 10)) {
    blockButton.style.display = 'none';
  } else {
    fetch(`/user_blocks/${profileUserId}`)
      .then(response => response.json())
      .then(response => {
        if (response.result === 'blocking') {
          blockButton.innerText = 'Unblock';
          blockButton.addEventListener('click', unblock, { once: true });
        } else {
          blockButton.addEventListener('click', block, { once: true });
        }
      });
  }
}
