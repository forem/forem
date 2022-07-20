import { toggleFlagUserModal } from '../packs/toggleUserFlagModal';
import { toggleSuspendUserModal } from '../packs/toggleUserSuspensionModal';
import { toggleUnpublishPostModal } from '../packs/unpublishPostModal';
import { toggleUnpublishAllPostsModal } from '../packs/modals/unpublishAllPosts';
import { request } from '@utilities/http';

export function addCloseListener() {
  const button = document.getElementsByClassName('close-actions-panel')[0];
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
  const butts = Array.from(
    document.querySelectorAll('.reaction-button, .reaction-vomit-button'),
  );
  /* eslint-disable camelcase */
  butts.forEach((butt) => {
    butt.addEventListener('click', async (event) => {
      event.preventDefault();
      const {
        reactableType: reactable_type,
        category,
        reactableId: reactable_id,
      } = butt.dataset;

      applyReactedClass(category);
      butt.classList.toggle('reacted');

      try {
        const response = await request('/reactions', {
          method: 'POST',
          body: { reactable_type, category, reactable_id },
        });

        const outcome = await response.json();

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
        }
        top.addSnackbarItem({
          message,
          addCloseButton: true,
        });
        /* eslint-enable no-restricted-globals */
      } catch (error) {
        // eslint-disable-next-line no-alert
        alert(error);
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

function clearAdjustmentReason() {
  document.getElementById('tag-adjustment-reason').value = '';
}

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

async function adjustTag(el) {
  const reasonForAdjustment = document.getElementById(
    'tag-adjustment-reason',
  ).value;
  const body = {
    tag_adjustment: {
      // TODO: change to tag ID
      tag_name: el.dataset.tagName || el.value,
      article_id: el.dataset.articleId,
      adjustment_type:
        el.dataset.adjustmentType === 'subtract' ? 'removal' : 'addition',
      reason_for_adjustment: reasonForAdjustment,
    },
  };

  try {
    const response = await request('/tag_adjustments', {
      method: 'POST',
      body: JSON.stringify(body),
    });

    const outcome = await response.json();

    if (outcome.status === 'Success') {
      let adjustedTagName;
      if (el.tagName === 'BUTTON') {
        adjustedTagName = el.dataset.tagName;
        el.remove();
      } else {
        adjustedTagName = el.value;
        // eslint-disable-next-line no-param-reassign, require-atomic-updates
        el.value = '';
      }

      clearAdjustmentReason();

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

export function handleAdjustTagBtn(btn) {
  const currentActiveTags = document.querySelectorAll(
    'button.adjustable-tag.active',
  );
  const adminTagInput = document.getElementById('admin-add-tag');
  /* eslint-disable no-restricted-globals */
  /* eslint-disable no-alert */
  if (
    adminTagInput &&
    adminTagInput.value !== '' &&
    confirm(
      'This will clear your current "Add a tag" input. Do you want to continue?',
    )
  ) {
    /* eslint-enable no-restricted-globals */
    /* eslint-enable no-alert */
    adminTagInput.value = '';
  } else if (currentActiveTags.length > 0) {
    currentActiveTags.forEach((tag) => {
      if (tag !== btn) {
        tag.classList.remove('active');
      }
      btn.classList.toggle('active');
    });
  } else {
    btn.classList.toggle('active');
  }
}

function handleAdminInput() {
  const addTagInput = document.getElementById('admin-add-tag');

  if (addTagInput) {
    addTagInput.addEventListener('focus', () => {
      const activeTagBtns = Array.from(
        document.querySelectorAll('button.adjustable-tag.active'),
      );
      activeTagBtns.forEach((btn) => {
        btn.classList.remove('active');
      });
    });
    addTagInput.addEventListener('focusout', () => {
      if (addTagInput.value === '') {
      }
    });
  }
}

export function addAdjustTagListeners() {
  Array.from(document.getElementsByClassName('adjustable-tag')).forEach(
    (btn) => {
      btn.addEventListener('click', () => {
        handleAdjustTagBtn(btn);
      });
    },
  );

  const form = document.getElementById('tag-adjust-submit')?.form;
  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();

      const dataSource =
        document.querySelector('button.adjustable-tag.active') ??
        document.getElementById('admin-add-tag');

      adjustTag(dataSource);
    });

    handleAdminInput();
  }
}

export function addModActionsListeners() {
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
