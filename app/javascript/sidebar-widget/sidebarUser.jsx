import { h, Component } from 'preact';
import PropTypes from 'prop-types';

class SidebarUser extends Component {
  constructor(props) {
    super(props);
    this.onClick = this.onClick.bind(this);
  }

  onClick() {
    this.props.followUser(this.props.user);
  }

  render() {
    return (
      <div className="widget-list-item__suggestions">
        <div className="widget-list-item__content">
          <a href={`/${this.props.user.username}`}>
            <img
              src={this.props.user.profile_image_url}
              alt={this.props.user.name}
              className="widget-list-item__profile-pic"
            />
            {this.props.user.name}
          </a>
          <button
            className="widget-list-item__follow-button"
            type="button"
            onClick={this.onClick}
            id={`widget-list-item__follow-button-${this.props.user.username}`}
          >
            {this.props.user.following ? '✓ FOLLOWING' : '+ FOLLOW'}
          </button>
        </div>
        <hr />
      </div>
    );
  }
}

SidebarUser.propTypes = {
  followUser: PropTypes.func.isRequired,
  user: PropTypes.object.isRequired,
};

export default SidebarUser;
