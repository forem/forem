import { updateExperienceLevel } from '../actionsPanel/actionsPanel';

/**
 * A thumbsup reaction on a comment/article will invalidate a previous thumbsdown
 * or vomit reaction (they will be deleted on the server by the reaction handler)
 * and vice versa. This function updates the UI to match.
 * @param {HTMLButtonElement} clickedBtn The reaction button that was clicked
 */
function toggleContradictoryReactions(clickedBtn) {
  const contentActions = document.querySelector('#content-mod-actions');

  if (clickedBtn.parentElement === contentActions) {
    const upVote = contentActions.querySelector("[data-category='thumbsup']");
    const downVote = contentActions.querySelector(
      "[data-category='thumbsdown']",
    );
    const vomitVote = contentActions.querySelector("[data-category='vomit']");

    if (clickedBtn.dataset.category === 'thumbsup') {
      downVote.classList.remove('reacted');
      vomitVote.classList.remove('reacted');
    } else {
      upVote.classList.remove('reacted');
    }
  }
}

async function updateMainReactions(clickedBtn) {
  const { reactableType, category, reactableId } = clickedBtn.dataset;
  try {
    const response = await fetch('/reactions', {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
      body: JSON.stringify({
        reactable_type: reactableType,
        category,
        reactable_id: reactableId,
      }),
    });

    const outcome = await response.json();

    if (outcome.result === 'create') {
      toggleContradictoryReactions(clickedBtn);
      clickedBtn.classList.add('reacted');
    } else if (outcome.result === 'destroy') {
      clickedBtn.classList.remove('reacted');
    } else {
      // eslint-disable-next-line no-alert
      alert(`Error: ${outcome.error}`);
      // eslint-disable-next-line no-console
      console.error(`Error: ${outcome.error}`);
    }
  } catch (error) {
    // eslint-disable-next-line no-alert
    alert(`Error: ${error}`);
  }
}

// Experience-Level JS
Array.from(document.getElementsByClassName('level-rating-button')).forEach(
  (btn) => {
    btn.addEventListener('click', () => {
      updateExperienceLevel(
        btn.dataset.userId,
        btn.dataset.articleId,
        btn.value,
        btn.dataset.group,
      );
    });
  },
);

document
  .querySelectorAll('.reaction-button, .reaction-vomit-button')
  .forEach((btn) => {
    btn.addEventListener('click', async () => {
      await updateMainReactions(btn);
    });
  });

const form = document.getElementsByClassName('button_to')[0];
if (form) {
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (confirm('Are you SURE you want to delete this comment?')) {
      form.submit();
    }
  });
}
