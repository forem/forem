import { h, Component } from 'preact';

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
        this.setState({ users: data, checkedUsers: data });
        console.log(data)
      })
      .catch(error => {
        console.log(error);
      });
  }

  handleComplete() {
    const csrfToken = getContentOfToken('csrf-token');
    this.state.selectedUsers.forEach(user => {
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
      }).catch(error => {
        console.log(error);
      });
    });
    this.props.next();
  }

  handleClick(user) {
    if (!this.state.selectedUsers.includes(user)) {
      this.setState(state => ({
        selectedTags: [...state.selectedUsers, user],
      }));
    } else {
      const selectedUsers = [...this.state.selectedUsers];
      const indexToRemove = selectedTags.indexOf(user);
      selectedUsers.splice(indexToRemove, 1);
      this.setState({
        selectedUsers,
      });
    }
  }

  render() {
    return (
      <div>
        <h2>Follow some users!</h2>
        {this.state.users.map(user => (
          <button onClick={() => this.handleClick(user)}>{user.name}</button>
        ))}
        <Navigation prev={this.props.prev} next={this.handleComplete} />
      </div>
    );
  }
}

export default FollowUsers;
