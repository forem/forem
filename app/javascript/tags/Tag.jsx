import { h } from 'preact';
import PropTypes from 'prop-types';

export const Tag = (props) => {
  const { following, hidden } = props.config;
  let followingButton;

  if (!hidden) {
    followingButton = (
      <button
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
