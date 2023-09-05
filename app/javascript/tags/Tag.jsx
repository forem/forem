import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { addSnackbarItem } from '../Snackbar';

/* global browserStoreCache */

/**
 * Renders the updated buttons component for a given tag card
 * @param {number} props.id The id of the tag
 * @param {string} props.name The name of the tag
 * @param {boolean} props.isFollowing Whether the user is following the tag
 * @param {string} props.isHidden Whether the tag is hidden
 *
 * @returns Updates the given Tag buttons (Follow and Hide) with the correct labels, buttons and actions.
 */
export const Tag = ({ id, name, isFollowing, isHidden }) => {
  const [following, setFollowing] = useState(isFollowing);
  const [hidden, setHidden] = useState(isHidden);

  let followingButton;

  const toggleFollowButton = () => {
    const updatedFollowState = !following;
    const hiddenState = hidden;

    postFollowItem({
      following: updatedFollowState,
      hidden: hiddenState,
    }).then((response) => {
      if (response.ok) {
        updateItem(
          null,
          updatedFollowState,
          `You have ${following ? 'un' : ''}followed ${name}.`,
        );
        return;
      }

      addSnackbarItem({
        message: `An error has occurred.`,
        addCloseButton: true,
      });
    });
  };

  const toggleHideButton = () => {
    const updatedHiddenState = !hidden;
    const updatedFollowState = true;

    postFollowItem({
      hidden: updatedHiddenState,
      following: updatedFollowState,
    }).then((response) => {
      if (response.ok) {
        updateItem(
          updatedHiddenState,
          updatedFollowState,
          `You have ${hidden ? 'un' : ''}hidden ${name}.`,
        );
        return;
      }

      addSnackbarItem({
        message: `An error has occurred.`,
        addCloseButton: true,
      });
    });
  };

  const updateItem = (updatedHiddenState, updatedFollowState, message) => {
    if (updatedHiddenState !== null) {
      setHidden(updatedHiddenState);
    }
    setFollowing(updatedFollowState);
    browserStoreCache('remove');
    addSnackbarItem({
      message,
      addCloseButton: true,
    });
    return;
  };

  const postFollowItem = ({ following, hidden }) => {
    return fetch('/follows', {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        followable_type: 'Tag',
        followable_id: id,
        verb: `${following ? '' : 'un'}follow`,
        explicit_points: hidden ? -1 : 1,
      }),
      credentials: 'same-origin',
    });
  };

  const hideButtonLabel = hidden ? 'Unhide' : 'Hide';
  const followButtonLabel = following ? 'Following' : 'Follow';

  if (!hidden) {
    followingButton = (
      <button
        onClick={toggleFollowButton}
        className={`crayons-btn ${
          following ? 'crayons-btn--outlined' : 'crayons-btn--primary'
        }`}
        aria-pressed={following}
        aria-label={`${followButtonLabel} tag: ${name}`}
      >
        {followButtonLabel}
      </button>
    );
  }

  return (
    <div>
      {followingButton}
      <button
        onClick={toggleHideButton}
        className={`crayons-btn ${
          hidden ? 'crayons-btn--danger' : 'crayons-btn--ghost'
        }`}
        aria-label={`${hideButtonLabel} tag: ${name}`}
      >
        {hideButtonLabel}
      </button>
    </div>
  );
};

Tag.propTypes = {
  id: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  following: PropTypes.bool,
  hidden: PropTypes.bool,
};
