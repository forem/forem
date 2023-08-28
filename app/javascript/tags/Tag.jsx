import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
/* global browserStoreCache */

export const Tag = ({config}) => {
  // const { following, hidden } = config;
  // maybe change following to follow?
  const [following, setFollowing] = useState(config.following);
  const [hidden, setHidden] = useState(config.hidden);

  const { id } = config;

  let followingButton;

  // TODO: handle click if logged out
  const toggleFollowButton = () => {
    setFollowing(!following);
    browserStoreCache('remove');
    postFollow();
  };

  const postFollow = () => {
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
        verb: 'follow',
      }),
      credentials: 'same-origin',
    })
      .then((response) => {
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
        data-info='{"followStyle":"primary","id":39,"className":"Tag","name":"facebook"}'
      >
        {following ? 'Following' : 'Follow'}
      </button>
    );
  }

  return (
    <div>
      {followingButton}
      <button
        className={`crayons-btn ${
          hidden ? 'crayons-btn--danger' : 'crayons-btn--ghost'
        }`}
        data-info='{"followStyle":"primary","id":39,"className":"Tag","name":"facebook"}'
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
