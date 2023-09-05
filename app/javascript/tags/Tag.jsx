import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
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
    setFollowing(!following);
    browserStoreCache('remove');
    postFollowItem({ following: !following, hidden });
  };

  const toggleHideButton = () => {
    const updatedHiddenState = !hidden;
    setHidden(updatedHiddenState);

    // if the tag's new state will be hidden (clicked on the hide button) then we we set it to following.
    // if the tags new state is to be unhidden (clicked on the unhide button) then we set it to not following.
    const updatedFollowingState = updatedHiddenState;
    setFollowing(updatedFollowingState);

    browserStoreCache('remove');
    postFollowItem({
      hidden: updatedHiddenState,
      following: updatedFollowingState,
    });
  };

  const postFollowItem = ({ following, hidden }) => {
    fetch('/follows', {
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
    }).then((response) => {
      if (response.status !== 200) {
        // TODO: replace this with an actual modal
        alert('An error occurred');
      }
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
  id: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  following: PropTypes.bool.isRequired,
  hidden: PropTypes.bool.isRequired,
};
