import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
/* global browserStoreCache  */

export const Tag = ({ config }) => {
  const [following, setFollowing] = useState(config.following);
  const [hidden, setHidden] = useState(config.hidden);

  const { id, name } = config;

  let followingButton;

  // TODO: handle click if logged out
  const toggleFollowButton = () => {
    setFollowing(!following);
    browserStoreCache('remove');
    postFollowItem({ following: !following, hidden });
  };

  const toggleHideButton = () => {
    setHidden(!hidden);
    browserStoreCache('remove');
    const updatedFollowing = true;
    setFollowing(updatedFollowing);
    postFollowItem({ hidden: !hidden, following: updatedFollowing });
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
        // TODO: handle error
      }
    });
  };

  if (!hidden) {
    followingButton = (
      <button
        onClick={toggleFollowButton}
        className={`crayons-btn ${
          following ? 'crayons-btn--outlined' : 'crayons-btn--primary'
        }`}
        aria-pressed={following}
        aria-label={`${following ? 'Following' : 'Follow'} tag: ${name}`}
      >
        {following ? 'Following' : 'Follow'}
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
      >
        {hidden ? 'Unhide' : 'Hide'}
      </button>
    </div>
  );
};

Tag.propTypes = {
  config: PropTypes.shape({
    following: PropTypes.bool,
    hidden: PropTypes.bool,
  }).isRequired,
};
