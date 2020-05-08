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

function correctReactedClasses(category) {
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

function addReactionButtonListeners() {
  const butts = Array.from(
    document.querySelectorAll('.reaction-button, .reaction-vomit-button'),
  );
  /* eslint-disable camelcase */
  butts.forEach((butt) => {
    butt.addEventListener('click', (event) => {
      event.preventDefault();
      const {
        reactableType: reactable_type,
        category,
        reactableId: reactable_id,
      } = butt.dataset;

      correctReactedClasses(category);
      butt.classList.toggle('reacted');

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

function toggleSubmitContainer() {
  document
    .getElementById('adjustment-reason-container')
    .classList.toggle('hidden');
}

function adjustTag(tagBtn) {
  const reasonForAdjustment = document.getElementById('tag-adjustment-reason')
    .value;
  const body = {
    tag_adjustment: {
      // TODO: change to tag ID
      tag_name: tagBtn.dataset.tagName,
      article_id: tagBtn.dataset.articleId,
      adjustment_type:
        tagBtn.dataset.adjustmentType === 'subtract' ? 'removal' : 'addition',
      reason_for_adjustment: reasonForAdjustment,
    },
  };

  request('/tag_adjustments', {
    method: 'POST',
    body: JSON.stringify(body),
  })
    .then((response) => response.json())
    .then((json) => {
      if (json.status === 'Success') {
        const { tagName } = tagBtn.dataset;
        tagBtn.remove();
        toggleSubmitContainer();

        if (json.result === 'addition') {
          const articleTagsContainer = window.parent.document.getElementsByClassName(
            'tags',
          )[0];

          const newTag = document.createElement('a');
          newTag.innerText = `#${tagName}`;
          newTag.setAttribute('class', 'tag');
          newTag.setAttribute('href', `/t/${tagName}`);
          newTag.style = `background-color: ${json.colors.bg}; color: ${json.colors.text};`;

          articleTagsContainer.appendChild(newTag);
        } else {
          const tagOnArticle = window.parent.document.querySelector(
            `.tag[href="/t/${tagName}"]`,
          );
          tagOnArticle.remove();
        }

        // eslint-disable-next-line no-alert
        alert(
          `#${tagName} was ${
            json.result === 'addition' ? 'added' : 'removed'
          }!`,
        );
      } else {
        // eslint-disable-next-line no-alert
        alert(json.error);
      }
    });
}

function addAdjustTagListeners() {
  Array.from(document.getElementsByClassName('adjustable-tag')).forEach(
    (btn) => {
      btn.addEventListener('click', () => {
        btn.classList.toggle('active');
        toggleSubmitContainer();
      });
    },
  );
  Array.from(document.getElementsByClassName('tag-adjust-submit')).forEach(
    (btn) => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const textArea = document.getElementById('tag-adjustment-reason');

        if (textArea.checkValidity()) {
          const dataButton = document.querySelector(
            'button.adjustable-tag.active',
          );
          adjustTag(dataButton);
        }
      });
    },
  );
}

function addBottomActionsListeners() {
  addAdjustTagListeners();
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
