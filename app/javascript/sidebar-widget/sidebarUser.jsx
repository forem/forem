import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { userPropTypes } from '../common-prop-types';

export class SidebarUser extends Component {
  constructor(props) {
    super(props);
    this.onClick = this.onClick.bind(this);
  }

  onClick() {
    const { followUser, user } = this.props;
    followUser(user);
  }

  render() {
    const { user } = this.props;
    return (
      <div className="widget-list-item__suggestions">
        <a
          data-testid="widget-avatar"
          href={`/${user.username}`}
          className="widget-list-item__avatar"
        >
          <img
            src={user.profile_image_url}
            alt={user.name}
            className="widget-list-item__profile-pic"
          />
        </a>
        <div data-testid="widget-content" className="widget-list-item__content">
          <h5>
            <a href={`/${user.username}`}>{user.name}</a>
          </h5>
          <button
            data-testid="widget-follow-button"
            className="widget-list-item__follow-button"
            type="button"
            onClick={this.onClick}
            id={`widget-list-item__follow-button-${user.username}`}
          >
            {user.following ? 'Following' : 'Follow'}
          </button>
        </div>
      </div>
    );
  }
}

SidebarUser.propTypes = {
  followUser: PropTypes.func.isRequired,
  user: PropTypes.objectOf(userPropTypes).isRequired,
};
