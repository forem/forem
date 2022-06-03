import { h, render } from 'preact';
import PropTypes from 'prop-types';
import { request } from '../utilities/http';
import { ButtonNew as Button } from '@crayons';
import RemoveIcon from '@images/x.svg';

async function confirmAdminUnpublishPost(id, username, slug) {
  try {
    const response = await request(`/articles/${id}/admin_unpublish`, {
      method: 'PATCH',
      body: JSON.stringify({ id, username, slug }),
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

  toggleUnpublishPostModal();
}

/**
 * Shows or hides the flag user modal.
 */
export function toggleUnpublishPostModal() {
  const modalContainer = top.document.getElementsByClassName(
    'unpublish-post-modal-container',
  )[0];
  modalContainer.classList.toggle('hidden');

  if (!modalContainer.classList.contains('hidden')) {
    top.window.scrollTo(0, 0);
    top.document.body.style.height = '100vh';
    top.document.body.style.overflowY = 'hidden';
  } else {
    top.document.body.style.height = 'inherit';
    top.document.body.style.overflowY = 'inherit';
  }
}

/**
 * Initializes the Unpublish Post modal for the given article ID, author username and article slug.
 *
 * @param {number} articleId
 * @param {string} authorUsername
 * @param {string} articleSlug
 */
export function initializeUnpublishPostModal(
  articleId,
  authorName,
  authorUsername,
  articleSlug,
) {
  // Check whether context is ModCenter or Friday-Night-Mode
  const modContainer = document.getElementById('mod-container');

  if (!modContainer) {
    return;
  }

  render(
    <UnpublishPostModal
      articleId={articleId}
      authorName={authorName}
      authorUsername={authorUsername}
      articleSlug={articleSlug}
    />,
    document.getElementsByClassName('unpublish-post-modal-container')[0],
  );
}

/**
 * A modal for unpublishing a post. This can be used in the moderation center
 * or on an article page.
 *
 * @param {number} props.articleId ID of the article to be unpublished.
 * @param {string} props.authorUsername Username of the article's author.
 * @param {string} props.articleSlug Slug of the article to be unpublished.
 */
export function UnpublishPostModal({
  articleId,
  authorName,
  authorUsername,
  articleSlug,
}) {
  return (
    <div
      data-testid="unpublish-post-modal"
      class="crayons-modal crayons-modal--small absolute unpublish-post-modal"
    >
      <div class="crayons-modal__box">
        <header class="crayons-modal__box__header unpublish-post-modal-header">
          <h2 class="crayons-modal__box__header__title">Unpublish post</h2>
          <Button
            icon={RemoveIcon}
            className="inline-flex"
            onClick={toggleUnpublishPostModal}
          />
        </header>
        <div class="crayons-modal__box__body">
          <div class="grid gap-4">
            <p>
              Once unpublished, this post will become invisible to the public
              and only accessible to {authorName}.
            </p>
            <p>They can still re-publish the post if they are not suspended.</p>
            <div>
              <Button
                destructive
                variant="primary"
                className="mr-2"
                id="confirm-unpublish-post-action"
                onClick={(_event) => {
                  confirmAdminUnpublishPost(
                    articleId,
                    authorUsername,
                    articleSlug,
                  );
                }}
              >
                Unpublish post
              </Button>
            </div>
          </div>
        </div>
      </div>
      <div
        role="presentation"
        class="crayons-modal__overlay"
        onClick={toggleUnpublishPostModal}
        onKeyUp={toggleUnpublishPostModal}
      />
    </div>
  );
}

UnpublishPostModal.displayName = 'UnpublishPostModal';
UnpublishPostModal.propTypes = {
  articleId: PropTypes.number.isRequired,
  authorUsername: PropTypes.string.isRequired,
  articleSlug: PropTypes.string.isRequired,
};
