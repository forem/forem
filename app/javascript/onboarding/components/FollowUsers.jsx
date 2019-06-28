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
    fetch('/api/users?state=follow_suggestions', {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then(data => {
        this.setState({ users: data });
      });
  }

  handleComplete() {
    const csrfToken = getContentOfToken('csrf-token');
    const { selectedUsers } = this.state;
    const { next } = this.props;

    selectedUsers.forEach(user => {
      fetch('/follows', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          followable_type: 'User',
          followable_id: user.id,
          verb: 'follow',
        }),
        credentials: 'same-origin',
      });
    });

    next();
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
      <div>
        <h2>Follow some users!</h2>
        <div className="scroll">
          {users.map(user => (
            <button
              type="button"
              style={{
                backgroundColor: selectedUsers.includes(user)
                  ? '#ddd'
                  : 'white',
              }}
              onClick={() => this.handleClick(user)}
              className="user"
            >
              <img src={user.profile_image_url} alt="" />
              {user.name}
            </button>
          ))}
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
