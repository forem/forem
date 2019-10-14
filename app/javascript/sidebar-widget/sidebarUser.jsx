import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import userPropTypes from '../src/components/common-prop-types/user-prop-types';

class SidebarUser extends Component {
  constructor(props) {
    super(props);
    this.onClick = this.onClick.bind(this);
  }

  onClick() {
    const { followUser, user } = this.props;
    followUser(user);
  }

  render() {
    const { user, index } = this.props;
    return (
      <div className="widget-list-item__suggestions">
        <div className="widget-list-item__content">
          <a href={`/${user.username}`}>
            <img
              src={user.profile_image_url}
              alt={user.name}
              className="widget-list-item__profile-pic"
            />
            {user.name}
          </a>
          <button
            className="widget-list-item__follow-button"
            type="button"
            onClick={this.onClick}
            id={`widget-list-item__follow-button-${user.username}`}
          >
            {user.following ? '✓ FOLLOWING' : '+ FOLLOW'}
          </button>
        </div>
        {index === 2 ? <br /> : <hr />}
      </div>
    );
  }
}

SidebarUser.propTypes = {
  followUser: PropTypes.func.isRequired,
  user: PropTypes.objectOf(userPropTypes).isRequired,
  index: PropTypes.number.isRequired,
};

export default SidebarUser;
