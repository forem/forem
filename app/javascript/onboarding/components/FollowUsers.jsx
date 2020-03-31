import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

class FollowUsers extends Component {
  constructor(props) {
    super(props);

    this.handleClick = this.handleClick.bind(this);
    this.handleComplete = this.handleComplete.bind(this);

    this.state = {
      users: [],
      selectedUsers: [],
    };
  }

  componentDidMount() {
    fetch('/users?state=follow_suggestions', {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then(data => {
        this.setState({ users: data, selectedUsers: data });
      });

    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: { last_onboarding_page: 'follow users page' },
      }),
      credentials: 'same-origin',
    });
  }

  handleComplete() {
    const csrfToken = getContentOfToken('csrf-token');
    const { selectedUsers } = this.state;
    const { next } = this.props;

    fetch('/api/follows', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ users: selectedUsers }),
      credentials: 'same-origin',
    });

    next();
  }

  handleSelectAll() {
    const { selectedUsers, users } = this.state;
    if (selectedUsers.length === users.length) {
      this.setState({
        selectedUsers: [],
      });
    } else {
      this.setState({
        selectedUsers: users,
      });
    }
  }

  handleClick(user) {
    let { selectedUsers } = this.state;

    if (!selectedUsers.includes(user)) {
      this.setState(prevState => ({
        selectedUsers: [...prevState.selectedUsers, user],
      }));
    } else {
      selectedUsers = [...selectedUsers];
      const indexToRemove = selectedUsers.indexOf(user);
      selectedUsers.splice(indexToRemove, 1);
      this.setState({
        selectedUsers,
      });
    }
  }

  render() {
    const { users, selectedUsers } = this.state;
    const { prev } = this.props;
    return (
      <div className="onboarding-main">
        <Navigation prev={prev} next={this.handleComplete} />
        <div className="onboarding-content">
          <header className="onboarding-content-header">
            <h1 className="title">Suggested people to follow</h1>
            <h2 className="subtitle">Let&apos;s review a few things first</h2>
          </header>

          <div className="onboarding-modal-scroll-container">
            {users.map(user => (
              <button
                type="button"
                onClick={() => this.handleClick(user)}
                onKeyDown={() => this.handleKeyDown(user)}
                className={
                  selectedUsers.includes(user)
                    ? 'user content-row selected'
                    : 'user content-row unselected'
                }
              >
                <figure className="user-avatar-container">
                  <img
                    className="user-avatar"
                    src={user.profile_image_url}
                    alt="profile"
                  />
                </figure>
                <div className="user-info">
                  <h4 className="user-name">{user.name}</h4>
                  <p className="user-summary">{user.summary}</p>
                </div>
                <button type="button" className="user-following-status">
                  {selectedUsers.includes(user) ? 'Following' : 'Follow'}
                </button>
              </button>
            ))}
          </div>
        </div>
        <div className="onboarding-selection-status">
          <div className="selection-status-content">
            <button type="button" onClick={() => this.handleSelectAll()}>
              Select All 
              {' '}
              {selectedUsers.length === users.length ? '✅' : ''}
            </button>
          </div>
        </div>
      </div>
    );
  }
}

FollowUsers.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default FollowUsers;
