const buttons = document.querySelectorAll('.reaction-button, .reaction-vomit-button');

function applyReactedClass(category) {
  const upVote = document.querySelector("[data-category='thumbsup']");
  const downVote = document.querySelector("[data-category='thumbsdown']");
  const vomitVote = document.querySelector("[data-category='vomit']");

  if (category === 'thumbsup') {
    downVote.classList.remove('reacted');
    vomitVote.classList.remove('reacted');
  } else {
    upVote.classList.remove('reacted');
  }
}

for (let i = 0; i < buttons.length; i++) {
  let button = buttons[i];
  button.onclick = function (event) {
    event.preventDefault();
    let thisButton = this;
    applyReactedClass(thisButton.dataset.category);
    thisButton.classList.add('reacted');

    function successCb(response) {
      if (response.result === 'create') {
        thisButton.classList.add('reacted');
      } else {
        thisButton.classList.remove('reacted');
      }
    }

    let formData = new FormData();
    formData.append('reactable_type', thisButton.dataset.reactableType);
    formData.append('category', thisButton.dataset.category);
    formData.append('reactable_id', thisButton.dataset.reactableId);

    getCsrfToken()
      .then(sendFetch('reaction-creation', formData))
      .then(function (response) {
        if (response.status === 200) {
          response.json().then(successCb);
        }
      });
  };
}

// Experience-Level JS
function clearExpLevels() {
  Array.from(
    document.getElementsByClassName('level-rating-button selected'),
  ).forEach((el) => {
    el.classList.remove('selected');
  });
}

async function updateExperienceLevel(currentUserId, articleId, rating, group) {
  try {
    const response = await fetch('/rating_votes', {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
      body: JSON.stringify({
        user_id: currentUserId,
        article_id: articleId,
        rating,
        group,
      }),
    });

    const outcome = await response.json();

    if (outcome.result === 'Success') {
      clearExpLevels();
      document
        .getElementById(`js__rating__vote__${rating}`)
        .classList.add('selected');
    } else {
      // eslint-disable-next-line no-alert
      alert(outcome.error);
    }
  } catch (error) {
    // eslint-disable-next-line no-alert
    alert(error);
  }
}

document.querySelectorAll('.level-rating-button').forEach((btn) => {
  btn.addEventListener('click', () => {
    updateExperienceLevel(
      btn.dataset.userId,
      btn.dataset.articleId,
      btn.value,
      btn.dataset.group,
    );
  });
});
