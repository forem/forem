import { h, Component } from 'preact';
import { sendFollowUser } from '../utilities/sendFollowUser';
import { SidebarUser } from './sidebarUser';

export class SidebarWidget extends Component {
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
    this.setState({
      tagInfo: JSON.parse(
        document.getElementById('sidebarWidget__pack').dataset.tagInfo,
      ),
    });
  }

  getSuggestedUsers() {
    const { tagInfo } = this.state;
    fetch(`/users?state=sidebar_suggestions&tag=${tagInfo.name}`, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then((response) => response.json())
      .then((json) => {
        this.setState({ suggestedUsers: json });
      })
      .catch((error) => {
        this.setState({ suggestedUsers: [] });
        Honeybadger.notify(error);
      });
  }

  followUser(user) {
    const { suggestedUsers } = this.state;
    const updatedUser = user;
    const updatedSuggestedUsers = suggestedUsers;
    const userIndex = suggestedUsers.indexOf(user);

    const followBtn = document.getElementById(
      `widget-list-item__follow-button-${updatedUser.username}`,
    );
    followBtn.innerText = updatedUser.following ? 'Follow' : 'Following';

    const toggleFollowState = (newFollowState) => {
      updatedUser.following = newFollowState === 'followed';
      updatedSuggestedUsers[userIndex] = updatedUser;
      this.setState({ suggestedUsers: updatedSuggestedUsers });
    };
    sendFollowUser(user, toggleFollowState);
  }

  render() {
    const { suggestedUsers } = this.state;
    const users = suggestedUsers.map((user, index) => (
      <SidebarUser
        key={user.id}
        user={user}
        followUser={this.followUser}
        index={index}
      />
    ));

    if (suggestedUsers.length > 0) {
      return (
        <div className="widget" id="widget-00001">
          <div className="widget-suggested-follows-container">
            <header>
              <h4>who to follow</h4>
            </header>
            <div className="widget-body">{users}</div>
          </div>
        </div>
      );
    }
    return <div />;
  }
}
