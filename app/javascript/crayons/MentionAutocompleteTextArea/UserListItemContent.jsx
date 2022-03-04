import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';

/**
 * Component used to display user details in the MentionAutocomplete dropdown
 *
 * @param {object} props
 * @param {object} props.user The user data to populate the list item content with
 */
export const UserListItemContent = ({ user }) => (
  <Fragment>
    <span className="crayons-avatar crayons-avatar--l mr-2 shrink-0">
      <img
        src={user.profile_image_90}
        alt=""
        className="crayons-avatar__image "
      />
    </span>

    <div>
      <p className="crayons-autocomplete__name">{user.name}</p>
      <p className="crayons-autocomplete__username">{`@${user.username}`}</p>
    </div>
  </Fragment>
);

UserListItemContent.propTypes = {
  user: PropTypes.shape({
    name: PropTypes.string,
    username: PropTypes.string,
    profile_image_90: PropTypes.string,
  }).isRequired,
};
