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
        <div className="onboarding-content">
          <h2>Ok, here are some people we picked for you</h2>
          <div className="scroll">
            <div className="select-all-button-wrapper">
              <button type="button" onClick={() => this.handleSelectAll()}>
                Select All 
                {' '}
                {selectedUsers.length === users.length ? '✅' : ''}
              </button>
            </div>
            {users.map(user => (
              <button
                type="button"
                style={{
                  backgroundColor: selectedUsers.includes(user)
                    ? '#c7ffe8'
                    : 'white',
                }}
                onClick={() => this.handleClick(user)}
                className="user"
              >
                <div className="onboarding-user-follow-status">
                  {selectedUsers.includes(user) ? 'selected' : ''}
                </div>
                <img src={user.profile_image_url} alt="" />
                <span>{user.name}</span>
                <p>{user.summary}</p>
              </button>
            ))}
          </div>
        </div>
        <Navigation prev={prev} next={this.handleComplete} />
      </div>
    );
  }
}

FollowUsers.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default FollowUsers;
