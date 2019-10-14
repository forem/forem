function initBlock() {
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
        if (response.outcome === 'unblocked') {
          blockButton.removeEventListener('click', this);
          blockButton.innerText = 'Block';
          blockButton.addEventListener('click', block);
        }
      })
      .catch(e => {
        window.alert(`Something went wrong: ${e}`);
      });
  }

  function block() {
    const confirmBlock = window.confirm(
      'Are you sure you want to block this person? This will:\n- prevent them from commenting on your posts\n- block all notifications from them\n- prevent them from messaging you via DEV Connect',
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
          if (response.outcome === 'blocked') {
            blockButton.removeEventListener('click', this);
            blockButton.innerText = 'Unblock';
            blockButton.addEventListener('click', unblock);
          }
        })
        .catch(e => {
          window.alert(`Something went wrong: ${e}`);
        });
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    // userData() is a global function
    const currentUserId = userData().id;

    if (currentUserId === parseInt(profileUserId, 10)) {
      blockButton.style.display = 'none';
    } else {
      fetch(`/user_blocks/${profileUserId}`)
        .then(response => response.text())
        .then(response => {
          if (response === 'blocking') {
            blockButton.innerText = 'Unblock';
            blockButton.addEventListener('click', unblock);
          } else {
            blockButton.addEventListener('click', block);
          }
        });
    }
  });
}

window.InstantClick.on('change', () => {
  initBlock();
});

initBlock();
