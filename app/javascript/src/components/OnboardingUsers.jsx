import { h, render, Component } from 'preact';
import PropTypes from 'prop-types';

class OnboardingUsers extends Component {
  constructor(props) {
    super(props);
    this.handleAllClick = this.handleAllClick.bind(this);
  }

  handleAllClick() {
    this.props.handleCheckAllUsers();
  }

  render() {
    const followList = this.props.users.map((user) => {
      return (
        <div className="onboarding-user-list-row" key={user.id} >
          <div className="onboarding-user-list-key">
            <img
              src={user.profile_image_url}
              alt={user.name}
            />
            {user.name}
          </div>
          <div className="onboarding-user-list-checkbox">
            <button onClick={this.props.handleCheckUser.bind(this, user)} className={this.props.checkedUsers.indexOf(user) > -1 ? 'checked' : ''}>
              {this.props.checkedUsers.indexOf(user) > -1 ? '✓' : '+'}
            </button>
          </div>
        </div>
      );
    });

    return (
      <div className="onboarding-user-container">
        <div className="onboarding-user-cta">
          Here are some folks from the community you might want to follow <span class="yellow">based on your interests</span>
        </div>
        <div className="onboarding-user-list">
          <div className="onboarding-user-list-header onboarding-user-list-row">
            <div className="onboarding-user-list-key">
              Follow All
            </div>
            <div className="onboarding-user-list-checkbox">
              <button id="onboarding-user-follow-all-btn" onClick={this.handleAllClick} className={this.props.checkedUsers.length === this.props.users.length ? 'checked' : ''}>
                {this.props.checkedUsers.length === this.props.users.length ? '✓' : '+'}
              </button>
            </div>
          </div>
          <div className="onboarding-user-list-body">{followList}</div>
        </div>
      </div>
    );
  }
}

OnboardingUsers.propTypes = {
  handleCheckUser: PropTypes.func.isRequired,
  handleCheckAllUsers: PropTypes.func.isRequired,
};


export default OnboardingUsers;
