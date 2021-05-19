function initializeDiscussionLockButtons() {
  const articleContainer = document.getElementById('article-show-container');
  if (articleContainer) {
    const isDiscussionLocked = articleContainer.dataset.discussionLocked;

    if (isDiscussionLocked == 'true') {
      displayDiscussionLockReason();
      hideElementById('new_comment');
    } else {
      showElementById('discussion-lock-action');
    }

    displayButtons(articleContainer);
  }
  addConfirmationModalClickHandlers();
}

function displayDiscussionLockReason(reason) {
  const discussionLockReason = document.getElementById(
    'discussion-lock-reason',
  );
  if (discussionLockReason) {
    discussionLockReason.classList.remove('hidden');

    const discussionLockReasonText = document.getElementById(
      'discussion-lock-reason-text',
    );
    if (reason && discussionLockReasonText) {
      discussionLockReasonText.textContent = reason;
    }
  }
}

function hideDiscussionLockReason() {
  const discussionLockReason = document.getElementById(
    'discussion-lock-reason',
  );
  if (discussionLockReason) {
    discussionLockReason.classList.add('hidden');
  }

  const discussionLockReasonText = document.getElementById(
    'discussion-lock-reason-text',
  );
  if (discussionLockReasonText) {
    discussionLockReasonText.textContent = '';
  }
}

function displayButtons() {
  var user = userData();
  var articleContainer = document.getElementById('article-show-container');
  if (user && articleContainer) {
    var authorId = parseInt(articleContainer.dataset.authorId, 10);

    if (user.admin || authorId === user.id) {
      var discussionLockButts = document.getElementsByClassName(
        'discussion-lock-actions',
      );

      for (let i = 0; i < discussionLockButts.length; i += 1) {
        let butt = discussionLockButts[i];
        butt.classList.remove('hidden');
      }
    }
  }
}

function addConfirmationModalClickHandlers() {
  const discussionLockButton = document.getElementById('discussion-lock-btn');
  if (discussionLockButton) {
    discussionLockButton.addEventListener('click', function (e) {
      showElementById('discussion-lock-confirmation-modal');
    });
  }

  const discussionLockCancelBtn = document.getElementById(
    'discussion-lock-cancel-btn',
  );
  if (discussionLockCancelBtn) {
    discussionLockCancelBtn.addEventListener('click', function (e) {
      hideElementById('discussion-lock-confirmation-modal');
    });
  }

  const closeDiscussionLockConfirmationModal = document.getElementById(
    'close-discussion-lock-confirmation-modal',
  );
  if (closeDiscussionLockConfirmationModal) {
    closeDiscussionLockConfirmationModal.addEventListener(
      'click',
      function (e) {
        hideElementById('discussion-lock-confirmation-modal');
      },
    );
  }

  const discussionLockConfirmationBtn = document.getElementById(
    'lock-discussion-btn',
  );
  if (discussionLockConfirmationBtn) {
    discussionLockConfirmationBtn.addEventListener('click', function (e) {
      handleLockDiscussion();
    });
  }

  const reopenDiscussionBtn = document.getElementById(
    'discussion-lock-reopen-btn',
  );
  if (reopenDiscussionBtn) {
    reopenDiscussionBtn.addEventListener('click', function (e) {
      handleReopenDiscussion();
    });
  }
}

function submitDiscussionLock() {
  const discussionLockConfirmationBtn = document.getElementById(
    'lock-discussion-btn',
  );
  if (discussionLockConfirmationBtn) {
    discussionLockConfirmationBtn.textContent = 'Locking...';
    discussionLockConfirmationBtn.disabled = true;
  }

  const discussionLockHeaders = {
    Accept: 'application/json',
    'X-CSRF-Token': window.csrfToken,
    'Content-Type': 'application/json',
  };

  const articleBody = document.getElementById('article-body');
  const articleId = articleBody ? articleBody.dataset.articleId : null;
  const reasonFieldValue = document.getElementById(
    'discussion-lock-reason-field',
  ).value;
  const discussionLockReason =
    reasonFieldValue === '' ? null : reasonFieldValue;
  const body = JSON.stringify({
    discussion_lock: {
      article_id: articleId,
      reason: discussionLockReason,
    },
  });

  return fetch('/discussion_locks', {
    method: 'POST',
    headers: discussionLockHeaders,
    credentials: 'same-origin',
    body: body,
  }).then(function (response) {
    return response.json();
  });
}

function submitReopenDiscussion() {
  const reopenDiscussionBtn = document.getElementById(
    'discussion-lock-reopen-btn',
  );
  if (reopenDiscussionBtn) {
    reopenDiscussionBtn.textContent = 'Reopening...';
    reopenDiscussionBtn.disabled = true;
  }

  const discussionLockHeaders = {
    Accept: 'application/json',
    'X-CSRF-Token': window.csrfToken,
    'Content-Type': 'application/json',
  };

  const discussionLockId = reopenDiscussionBtn
    ? reopenDiscussionBtn.dataset.discussionLockId
    : null;

  return fetch(`/discussion_locks/${discussionLockId}`, {
    method: 'DELETE',
    headers: discussionLockHeaders,
    credentials: 'same-origin',
  }).then(function (response) {
    return response.json();
  });
}

function hideElementById(elementId) {
  const element = document.getElementById(elementId);
  if (element) {
    element.classList.add('hidden');
  }
}

function showElementById(elementId) {
  const element = document.getElementById(elementId);
  if (element) {
    element.classList.remove('hidden');
  }
}

function updateDiscussionLock(isLocked) {
  const articleContainer = document.getElementById('article-show-container');
  if (articleContainer) {
    articleContainer.setAttribute('discussion-locked', isLocked);
  }
}

function hideErrorMsg(elementId) {
  const errorMsg = document.getElementById(elementId);
  if (errorMsg) {
    errorMsg.classList.add('hidden');
    errorMsg.textContent = '';
  }
}

function showErrorMsg(elementId, msg) {
  const errorMsg = document.getElementById(elementId);
  if (errorMsg) {
    errorMsg.classList.remove('hidden');
    errorMsg.textContent = msg;
  }
}

function reenableDiscussionLockConfirmationBtn() {
  const discussionLockConfirmationBtn = document.getElementById(
    'lock-discussion-btn',
  );
  if (discussionLockConfirmationBtn) {
    discussionLockConfirmationBtn.textContent = 'Lock discussion';
    discussionLockConfirmationBtn.disabled = false;
  }
}

function reenableReopenDiscussionBtn() {
  const reopenDiscussionBtn = document.getElementById(
    'discussion-lock-reopen-btn',
  );
  if (reopenDiscussionBtn) {
    reopenDiscussionBtn.textContent = 'Reopen';
    reopenDiscussionBtn.disabled = false;
  }
}

function updateReopenDiscussionData(data) {
  const reopenDiscussionBtn = document.getElementById(
    'discussion-lock-reopen-btn',
  );
  if (reopenDiscussionBtn) {
    reopenDiscussionBtn.setAttribute('data-discussion-lock-id', data.id);
  }
}

function clearReopenDiscussionData() {
  const reopenDiscussionBtn = document.getElementById(
    'discussion-lock-reopen-btn',
  );
  if (reopenDiscussionBtn) {
    reopenDiscussionBtn.setAttribute('data-discussion-lock-id', null);
  }
}

function clearDiscussionLockForm() {
  const discussionLockReasonInput = document.getElementById(
    'discussion-lock-reason-field',
  );

  if (discussionLockReasonInput) {
    discussionLockReasonInput.value = '';
  }
}

function handleLockDiscussion() {
  submitDiscussionLock().then(function (response) {
    if (response.success) {
      hideErrorMsg('discussion-lock-error');
      hideElementById('discussion-lock-confirmation-modal');

      // We "manually" update the DOM because we bust caches async, which can take time
      hideElementById('discussion-lock-btn');
      displayDiscussionLockReason(response.data.reason);
      updateDiscussionLock('true');
      updateReopenDiscussionData(response.data);
      hideElementById('new_comment');
      clearDiscussionLockForm();
      reenableDiscussionLockConfirmationBtn();
    } else {
      console.error(`Discussion lock error: ${response.error}`);
      showErrorMsg('discussion-lock-error', response.error);
      reenableDiscussionLockConfirmationBtn();
    }
  });
}

function handleReopenDiscussion() {
  submitReopenDiscussion().then(function (response) {
    if (response.success) {
      hideErrorMsg('reopen-discussion-error');

      // We "manually" update the DOM because we bust caches async, which can take time
      showElementById('discussion-lock-btn');
      hideDiscussionLockReason();
      updateDiscussionLock('false');
      clearReopenDiscussionData();
      showElementById('new_comment');
      reenableReopenDiscussionBtn();
    } else {
      console.error(`Reopen discussion error: ${response.error}`);
      showErrorMsg('reopen-discussion-error', response.error);
      reenableReopenDiscussionBtn();
    }
  });
}
