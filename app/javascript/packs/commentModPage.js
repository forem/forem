import { updateExperienceLevel } from '../actionsPanel/actionsPanel';

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

async function updateMainReactions(reactableType, category, reactableId) {
  const clickedBtn = document.querySelector(`[data-category="${category}"]`);
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
    btn.addEventListener('click', () => {
      applyReactedClass(btn.dataset.category);
      updateMainReactions(
        btn.dataset.reactableType,
        btn.dataset.category,
        btn.dataset.reactableId,
      );
    });
  });

const form = document.getElementsByClassName('button_to')[0];
form.addEventListener('submit', (e) => {
  e.preventDefault();
  if (confirm('Are you SURE you want to delete this comment?')) {
    form.submit();
  }
});
