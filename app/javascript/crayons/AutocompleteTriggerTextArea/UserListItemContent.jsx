import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 * Component used to display user details in the Autocomplete dropdown
 *
 * @param {object} props
 * @param {string} props.name The user's name
 * @param {string} props.profile_image_90 The src of the user's profile image
 * @param {string} props.username The user's username
 */
export const UserListItemContent = ({ name, profile_image_90, username }) => (
  <div className="flex">
    <span className="crayons-avatar crayons-avatar--l mr-2 shrink-0">
      <img src={profile_image_90} alt="" className="crayons-avatar__image " />
    </span>

    <div>
      <p className="fs-m fw-medium">{name}</p>
      <p className="color-base-60 fs-s">{`@${username}`}</p>
    </div>
  </div>
);

UserListItemContent.propTypes = {
  name: PropTypes.string.isRequired,
  username: PropTypes.string.isRequired,
  profile_image_90: PropTypes.string.isRequired,
};
