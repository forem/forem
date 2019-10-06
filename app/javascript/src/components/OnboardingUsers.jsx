import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import userPropType from './common-prop-types/user-prop-types';

class OnboardingUsers extends Component {
  constructor(props) {
    super(props);
    this.handleAllClick = this.handleAllClick.bind(this);
  }

  handleAllClick() {
    const { handleCheckAllUsers } = this.props;
    handleCheckAllUsers();
  }

  render() {
    const { users, handleCheckUser, checkedUsers } = this.props;
    const followList = users.map(user => {
      return (
        <div className="onboarding-user-list-row" key={user.id}>
          <div className="onboarding-user-list-key">
            <img src={user.profile_image_url} alt={user.name} />
            <div>{user.name}</div>
            <div className="onboarding-user-list-row__summary">
              <em>{user.summary}</em>
            </div>
          </div>
          <div className="onboarding-user-list-checkbox">
            <button
              type="button"
              onClick={handleCheckUser.bind(this, user)}
              className={checkedUsers.indexOf(user) > -1 ? 'checked' : ''}
            >
              {checkedUsers.indexOf(user) > -1 ? '✓' : '+'}
            </button>
          </div>
        </div>
      );
    });
    const renderLoadingOrList = () => {
      if (users.length === 0) {
        return <div className="onboarding-user-loading">Loading...</div>;
      }
      return followList;
    };

    return (
      <div className="onboarding-user-container">
        <div className="onboarding-user-cta">
          Here are some suggestions based on your interests
        </div>
        <div className="onboarding-user-list">
          <div className="onboarding-user-list-header">
            <div className="onboarding-user-list-key">Follow All</div>
            <div className="onboarding-user-list-checkbox">
              <button
                type="button"
                id="onboarding-user-follow-all-btn"
                onClick={this.handleAllClick}
                className={
                  checkedUsers.length === users.length ? 'checked' : ''
                }
              >
                {checkedUsers.length === users.length ? '✓' : '+'}
              </button>
            </div>
          </div>
          <div className="onboarding-user-list-body">
            {renderLoadingOrList()}
          </div>
        </div>
      </div>
    );
  }
}

OnboardingUsers.propTypes = {
  handleCheckUser: PropTypes.func.isRequired,
  handleCheckAllUsers: PropTypes.func.isRequired,
  users: PropTypes.arrayOf(userPropType).isRequired,
  checkedUsers: PropTypes.arrayOf(PropTypes.object).isRequired,
};

export default OnboardingUsers;
