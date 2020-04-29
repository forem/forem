import { request } from '../utilities/http/request';

function addCloseListener() {
  const button = document.querySelector('.close-actions-panel');
  button.addEventListener('click', () => {
    // getting the article show page document because this is called within an iframe
    const articleDocument = window.parent.document;

    articleDocument
      .querySelector('.mod-actions-menu')
      .classList.toggle('showing');
    articleDocument
      .querySelector('.mod-actions-menu-btn')
      .classList.toggle('hidden');
  });
}

function initializeHeight() {
  document.documentElement.style.height = '100%';
  document.body.style.cssText = 'height: 100%; margin: 0; padding-top: 0;';
  document.getElementById('page-content').style.cssText =
    'margin-top: 0 !important; margin-bottom: 0;';
}

function toggleDropdown(type) {
  if (type === 'set-experience') {
    document
      .querySelector('.set-experience-options')
      .classList.toggle('hidden');
  } else if (type === 'adjust-tags') {
    document.querySelector('.adjust-tags-options').classList.toggle('hidden');
  }
}

function addReactionButtonListeners() {
  const butts = Array.from(
    document.querySelectorAll('.reaction-button, .reaction-vomit-button'),
  );
  /* eslint-disable camelcase */
  butts.forEach((butt) => {
    butt.addEventListener('click', (event) => {
      event.preventDefault();
      this.classList.add('reacted');
      const {
        reactableType: reactable_type,
        category,
        reactableId: reactable_id,
      } = this.dataset;

      request('/reactions', {
        method: 'POST',
        body: { reactable_type, category, reactable_id },
      });
    });
  });
  /* eslint-enable camelcase */
}

function clearExpLevels() {
  Array.from(
    document.getElementsByClassName('level-rating-button selected'),
  ).forEach((el) => {
    el.classList.remove('selected');
  });
}

function updateExperienceLevel(currentUserId, articleId, rating, group) {
  request('/rating_votes', {
    method: 'POST',
    body: JSON.stringify({
      user_id: currentUserId,
      article_id: articleId,
      rating,
      group,
    }),
  }).then((response) =>
    response
      .json()
      .then((json) => {
        if (json.result === 'Success') {
          clearExpLevels();
          document
            .getElementById(`js__rating__vote__${rating}`)
            .classList.add('selected');
        } else {
          // eslint-disable-next-line no-alert
          alert(json.error);
        }
      })
      .catch((error) => {
        // eslint-disable-next-line no-alert
        alert(error);
      }),
  );
}

function addBottomActionsListeners() {
  Array.from(document.getElementsByClassName('other-things-btn')).forEach(
    (btn) => {
      btn.addEventListener('click', () => {
        btn.classList.toggle('active');
        const otherBtns = Array.from(
          document.getElementsByClassName('other-things-btn'),
        ).filter((otherBtn) => otherBtn !== btn);
        otherBtns.forEach((otherBtn) => {
          otherBtn.classList.toggle('inactive');
        });

        btn.querySelector('.label-wrapper > .icon').classList.toggle('hidden');
        btn
          .querySelector('.toggle-chevron-container')
          .classList.toggle('rotated');
        toggleDropdown(btn.dataset.otherThingsType);
      });
    },
  );

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
}

export function initializeActionsPanel() {
  initializeHeight();
  addCloseListener();
  addReactionButtonListeners();
  addBottomActionsListeners();
}
