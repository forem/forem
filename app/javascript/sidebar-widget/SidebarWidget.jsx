import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import sendFollowUser from '../src/utils/sendFollowUser';
import SidebarUser from './sidebarUser';

class SidebarWidget extends Component {
  constructor(props) {
    super(props);
    this.getSuggestedUsers = this.getSuggestedUsers.bind(this);
    this.getTagInfo = this.getTagInfo.bind(this);
    this.followUser = this.followUser.bind(this);
    this.state = {
      tagInfo: {},
      suggestedUsers: [],
    };
  }
  
  componentDidMount() {
    this.getTagInfo();
    this.getSuggestedUsers();
  }

  getTagInfo() {
    this.setState({ tagInfo: JSON.parse(document.getElementById('sidebarWidget__pack').dataset.tagInfo) });
  }

  getSuggestedUsers() {
    fetch(`/api/users/sidebar_suggestions?tag=${this.state.tagInfo.name}`, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then((json) => {
        this.setState({ suggestedUsers: json });
      })
      .catch((error) => {
        console.log(error);
      });
  }

  followUser(user) {
    const toggleFollowState = (newFollowState) => {
      const updatedUser = user;
      const updatedSuggestedUsers = this.state.suggestedUsers;
      const userIndex = this.state.suggestedUsers.indexOf(user);
      updatedUser.following = newFollowState === 'followed';
      updatedSuggestedUsers[userIndex] = updatedUser;
      this.setState({ suggestedUsers: updatedSuggestedUsers });
    };
    sendFollowUser(user, toggleFollowState);
  }

  render() {
    const users = this.state.suggestedUsers.map((user) => {
      return(
        <SidebarUser key={user.id} user={user} followUser={this.followUser} />
      );
    });
    return (
      <div className="widget-suggested-follows-container">
        <header>
          {"<WHO TO FOLLOW>"}
        </header>
        <div className="widget-body">
          {users}
        </div>
      </div>
    );
  }
}

export default SidebarWidget;
