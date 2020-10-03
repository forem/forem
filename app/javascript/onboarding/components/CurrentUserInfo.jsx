import { h } from 'preact';
import PropTypes from 'prop-types';

const CurrentUserInfo = ({ name, username, imagePath }) => (
  <div className="current-user-info">
    <figure className="current-user-avatar-container">
      <img className="current-user-avatar" alt="profile" src={imagePath} />
    </figure>
    <h3>{name}</h3>
    <p>{username}</p>
  </div>
);

CurrentUserInfo.propTypes = {
  name: PropTypes.string.isRequired,
  username: PropTypes.string.isRequired,
  imagePath: PropTypes.string.isRequired,
};

export default CurrentUserInfo;
