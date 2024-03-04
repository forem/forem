import { toggleFlagUserModal } from '../packs/toggleUserFlagModal';
import { toggleSuspendUserModal } from '../packs/toggleUserSuspensionModal';
import { toggleUnpublishPostModal } from '../packs/unpublishPostModal';
import { toggleUnpublishAllPostsModal } from '../packs/modals/unpublishAllPosts';
import { postReactions } from './services/reactions';
import { request } from '@utilities/http';

export function addCloseListener() {
  const button = document.getElementsByClassName('close-actions-panel')[0];
  const parentPath = window.parent.location.pathname;
  if (!parentPath.startsWith('/mod')) {
    button.classList.remove('hidden');
  }

  button.addEventListener('click', () => {
    // getting the article show page document because this is called within an iframe
    // eslint-disable-next-line no-restricted-globals
    const articleDocument = top.document;

    articleDocument
      .getElementsByClassName('mod-actions-menu')[0]
      .classList.toggle('showing');
  });
}

export function initializeHeight() {
  document.documentElement.style.height = '100%';
  document.body.style.cssText =
    'height: 100%; margin: 0; padding-top: 0; overflow-y: hidden';
  document.getElementById('page-content').style.cssText =
    'margin-top: 0 !important; margin-bottom: 0;';
}

function toggleDropdown(type) {
  const controller = document.querySelector(
    `[aria-controls="${type}-options"]`,
  );
  controller.setAttribute(
    'aria-expanded',
    controller.getAttribute('aria-expanded') === 'true' ? 'false' : 'true',
  );

  document.querySelector(`#${type}-options`).classList.toggle('hidden');
}

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

export function addReactionButtonListeners() {
  const reactionButtons = Array.from(
    document.querySelectorAll('.reaction-button, .reaction-vomit-button'),
  );
  const initialButtonsState = {};

  reactionButtons.forEach((button) => {
    const { classList } = button;

    initialButtonsState[button.getAttribute('data-category')] =
      classList.contains('reacted');
  });

  const rollbackReactionButtonsState = () => {
    reactionButtons.forEach(({ classList, dataset }) => {
      if (initialButtonsState[dataset.category]) classList.add('reacted');
      else classList.remove('reacted');
    });
  };

  /* eslint-disable camelcase */
  reactionButtons.forEach((button) => {
    button.addEventListener('click', async (event) => {
      event.preventDefault();
      const {
        reactableType: reactable_type,
        category,
        reactableId: reactable_id,
      } = button.dataset;

      applyReactedClass(category);
      button.classList.toggle('reacted');

      try {
        const outcome = await postReactions({
          reactable_type,
          category,
          reactable_id,
        });

        let message;
        /* eslint-disable no-restricted-globals */
        if (outcome.result === 'create' && outcome.category === 'thumbsup') {
          message = 'This post will be more visible.';
        } else if (
          outcome.result === 'create' &&
          outcome.category === 'thumbsdown'
        ) {
          message = 'This post will be less visible.';
        } else if (
          outcome.result === 'create' &&
          outcome.category === 'vomit'
        ) {
          message = "You've flagged this post as abusive or spam.";
        } else if (outcome.result === 'destroy') {
          message = 'Your quality rating was removed.';
        } else if (outcome.error) {
          message = `Error: ${outcome.error}`;
          rollbackReactionButtonsState();
        }
        top.addSnackbarItem({
          message,
          addCloseButton: true,
        });
        /* eslint-enable no-restricted-globals */
      } catch (error) {
        // eslint-disable-next-line no-alert
        alert(error);
        rollbackReactionButtonsState();
      }
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

export async function updateExperienceLevel(
  currentUserId,
  articleId,
  rating,
  group,
) {
  try {
    const response = await request('/rating_votes', {
      method: 'POST',
      body: JSON.stringify({
        rating_vote: {
          user_id: currentUserId,
          article_id: articleId,
          rating,
          group,
        },
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

const adminFeatureArticle = async (id, featured) => {
  try {
    const response = await request(`/articles/${id}/admin_featured_toggle`, {
      method: 'PATCH',
      body: JSON.stringify({
        id,
        article: { featured: featured === 'true' ? 0 : 1 },
      }),
      credentials: 'same-origin',
    });

    const outcome = await response.json();

    /* eslint-disable no-restricted-globals */
    if (outcome.message == 'success') {
      window.top.location.assign(`${window.location.origin}${outcome.path}`);
    } else {
      top.addSnackbarItem({
        message: `Error: ${outcome.message}`,
        addCloseButton: true,
      });
    }
  } catch (error) {
    top.addSnackbarItem({
      message: `Error: ${error}`,
      addCloseButton: true,
    });
  }
};

function renderTagOnArticle(tagName, colors) {
  const articleTagsContainer =
    getArticleContainer().getElementsByClassName('spec__tags')[0];

  const newTag = document.createElement('a');
  newTag.innerHTML = `<span class="crayons-tag__prefix">#</span>${tagName}`;
  newTag.setAttribute('class', 'crayons-tag');
  newTag.setAttribute('href', `/t/${tagName}`);
  newTag.style = `--tag-bg: ${colors.bg}1a; --tag-prefix: ${colors.bg}; --tag-bg-hover: ${colors.bg}1a; --tag-prefix-hover: ${colors.bg};`;

  articleTagsContainer.appendChild(newTag);
}

function getArticleContainer() {
  const articleIframe =
    window.parent.document?.getElementsByClassName('article-iframe')[0];

  return articleIframe
    ? articleIframe.contentWindow.document
    : window.parent.document.getElementById('main-content');
}

/**
 * This function sends an asynchronous request to the server to add or remove
 * a specific tag from an article.
 */
async function adjustTag(el, reasonElement) {
  const tagName = el.dataset.tagName || el.value;
  const body = {
    tag_adjustment: {
      // TODO: change to tag ID
      tag_name: tagName,
      article_id: el.dataset.articleId,
      adjustment_type:
        el.dataset.adjustmentType === 'subtract' ? 'removal' : 'addition',
      reason_for_adjustment: reasonElement.value,
    },
  };

  try {
    const response = await fetch('/tag_adjustments', {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const outcome = await response.json();

    if (outcome.status === 'Success') {
      let adjustedTagName;
      if (el.tagName === 'BUTTON') {
        adjustedTagName = el.dataset.tagName;
      } else {
        adjustedTagName = el.value;
        // eslint-disable-next-line no-param-reassign, require-atomic-updates
        el.value = '';
      }

      if (outcome.result === 'addition') {
        renderTagOnArticle(adjustedTagName, outcome.colors);
      } else {
        getArticleContainer()
          .querySelector(`.crayons-tag[href="/t/${adjustedTagName}"]`)
          .remove();
      }

      // eslint-disable-next-line no-restricted-globals
      top.addSnackbarItem({
        message: `The #${adjustedTagName} tag was ${
          outcome.result === 'addition' ? 'added' : 'removed'
        }.`,
        addCloseButton: true,
      });
      // TODO: explore possible alternatives to reloading window, which seems to have the side effect
      // of making deferred JS load-in times unpredictable in e2e tests
      window.location.reload();
    } else {
      // eslint-disable-next-line no-restricted-globals
      top.addSnackbarItem({
        message: `An error occurred: ${outcome.error}`,
        addCloseButton: true,
      });
    }
  } catch (error) {
    // eslint-disable-next-line no-alert
    alert(error);
  }
}

export function handleAddModTagButton(btn) {
  const { tagName } = btn.dataset;
  const addButton = document.getElementById(`add-tag-button-${tagName}`);
  const addIcon = document.getElementById(`add-tag-icon-${tagName}`);
  const addTagContainer = document.getElementById(
    `add-tag-container-${tagName}`,
  );

  const containerIsVisible = addTagContainer.classList.contains('hidden');
  if (containerIsVisible) {
    addIcon.style.display = 'none';
    addTagContainer.classList.remove('hidden');
    addButton.classList.add('fw-bold');
    addButton.classList.remove('fw-normal');
  } else {
    addIcon.style.display = 'flex';
    addTagContainer.classList.add('hidden');
    addButton.classList.remove('fw-bold');
    addButton.classList.add('fw-normal');
  }

  const cancelAddModTagButton = document.getElementById(
    `cancel-add-tag-button-${tagName}`,
  );
  cancelAddModTagButton.addEventListener('click', () => {
    handleAddModTagButton(btn);
  });

  const addTagButton = document.getElementById(`tag-add-submit-${tagName}`);
  if (addTagButton) {
    addTagButton.addEventListener('click', (e) => {
      e.preventDefault();
      const dataSource = document.getElementById(`add-tag-button-${tagName}`);
      const reasonFoRemoval = document.getElementById(
        `tag-add-reason-${tagName}`,
      );
      adjustTag(dataSource, reasonFoRemoval);
    });
  }
}

/**
 * Handles various listeners required to handle remove tag functionality.
 */
export function handleRemoveTagButton(btn) {
  const { tagName } = btn.dataset;

  const removeButton = document.getElementById(`remove-tag-button-${tagName}`);
  const removeIcon = document.getElementById(`remove-tag-icon-${tagName}`);
  const removeTagContainer = document.getElementById(
    `remove-tag-container-${tagName}`,
  );

  if (!(removeButton && removeIcon && removeTagContainer)) {
    return false;
  }

  const containerIsVisible = removeTagContainer?.classList.contains('hidden');
  if (containerIsVisible) {
    removeIcon.style.display = 'none';
    removeTagContainer.classList.remove('hidden');
    removeButton.classList.add('fw-bold');
    removeButton.classList.remove('fw-normal');
  } else {
    removeIcon.style.display = 'flex';
    removeTagContainer.classList.add('hidden');
    removeButton.classList.remove('fw-bold');
    removeButton.classList.add('fw-normal');
  }

  const cancelRemoveTagButton = document.getElementById(
    `cancel-remove-tag-button-${tagName}`,
  );
  cancelRemoveTagButton.addEventListener('click', () => {
    handleRemoveTagButton(btn);
  });

  const removeTagButton = document.getElementById(
    `remove-tag-submit-${tagName}`,
  );
  if (removeTagButton) {
    removeTagButton.addEventListener('click', (e) => {
      e.preventDefault();

      const dataSource = document.getElementById(
        `remove-tag-button-${tagName}`,
      );
      const reasonFoRemoval = document.getElementById(
        `tag-removal-reason-${tagName}`,
      );
      adjustTag(dataSource, reasonFoRemoval);
    });
  }
}

/**
 * Handles various listeners required to handle add tag functionality.
 */
export function handleAddTagButtonListeners() {
  const inputTag = document.getElementById('admin-add-tag');
  const submitButton = document.getElementById('tag-add-submit');

  if (inputTag) {
    inputTag.addEventListener('input', () => {
      if (inputTag.value.trim().length > 0) {
        submitButton.removeAttribute('disabled');
      } else {
        submitButton.setAttribute('disabled', 'disabled');
      }
    });
  }

  const addTagButton = document.getElementById('add-tag-button');

  if (addTagButton) {
    addTagButton.addEventListener('click', () => {
      const addTagContainer = document.getElementById('add-tag-container');
      addTagContainer.classList.remove('hidden');
      addTagButton.classList.add('hidden');
    });

    const cancelAddTagButton = document.getElementById('cancel-add-tag-button');

    if (cancelAddTagButton) {
      cancelAddTagButton.addEventListener('click', () => {
        const addTagContainer = document.getElementById('add-tag-container');
        addTagContainer.classList.add('hidden');
        addTagButton.classList.remove('hidden');
      });
    }

    const addTagSubmitButton = document.getElementById('tag-add-submit');
    if (addTagSubmitButton) {
      addTagSubmitButton.addEventListener('click', (e) => {
        e.preventDefault();

        const dataSource = document.getElementById('admin-add-tag');
        const reasonFoAddition = document.getElementById('tag-add-reason');
        adjustTag(dataSource, reasonFoAddition);
      });
    }
  }
}

export function handleAddModTagButtonsListeners() {
  Array.from(document.getElementsByClassName('adjustable-tag add-tag')).forEach(
    (btn) => {
      btn.addEventListener('click', () => {
        handleAddModTagButton(btn);
      });
    },
  );
}

export function handleRemoveTagButtonsListeners() {
  Array.from(document.getElementsByClassName('adjustable-tag')).forEach(
    (btn) => {
      btn.addEventListener('click', () => {
        handleRemoveTagButton(btn);
      });
    },
  );
}

export function addModActionsListeners() {
  handleAddTagButtonListeners();
  handleAddModTagButtonsListeners();
  handleRemoveTagButtonsListeners();
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
          .getElementsByClassName('toggle-chevron-container')[0]
          .classList.toggle('rotated');
        toggleDropdown(btn.dataset.otherThingsType);
      });
    },
  );

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

  const featureArticleBtn = document.getElementById('feature-article-btn');
  if (featureArticleBtn) {
    featureArticleBtn.addEventListener('click', () => {
      const { articleId: id, articleFeatured: featured } =
        featureArticleBtn.dataset;
      adminFeatureArticle(id, featured);
    });
  }

  document
    .getElementById('toggle-flag-user-modal')
    .addEventListener('click', toggleFlagUserModal);

  document
    .getElementById('suspend-user-btn')
    ?.addEventListener('click', toggleSuspendUserModal);

  document
    .getElementById('unsuspend-user-btn')
    ?.addEventListener('click', toggleSuspendUserModal);

  document
    .getElementById('unpublish-all-posts-btn')
    ?.addEventListener('click', toggleUnpublishAllPostsModal);

  document
    .getElementById('unpublish-article-btn')
    ?.addEventListener('click', toggleUnpublishPostModal);
}

export function initializeActionsPanel() {
  initializeHeight();
  addCloseListener();
  addReactionButtonListeners();
  addModActionsListeners();
}
