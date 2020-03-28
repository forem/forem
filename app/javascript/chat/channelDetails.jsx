import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import debounceAction from '../src/utils/debounceAction';

class ChannelDetails extends Component {
  static propTypes = {
    channel: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  };

  constructor(props) {
    super(props);

    this.debouncedUserSearch = debounceAction(
      this.triggerUserSearch.bind(this),
      { config: { leading: true } },
    );

    this.state = {
      searchedUsers: [],
      hasLeftChannel: false,
    };
  }

  triggerUserSearch = e => {
    const component = this;
    const query = e.target.value;
    if (query.length > 0) {
      const searchHash = { per_page: 20, search_fields: query };
      const searchParams = new URLSearchParams(searchHash).toString();
      fetch(`/search/users?${searchParams}`, {
        method: 'GET',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': window.csrfToken,
          'Content-Type': 'application/json',
        },
        credentials: 'same-origin',
      })
        .then(response => response.json())
        .then(response => {
          component.setState({ searchedUsers: response.result });
        });
    } else {
      component.setState({ searchedUsers: [] });
    }
  };

  triggerInvite = e => {
    const component = this;
    const id = e.target.dataset.content;
    e.target.style.display = 'none';
    fetch(`/chat_channel_memberships`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_channel_membership: {
          user_id: id,
          chat_channel_id: component.props.channel.id,
        },
      }),
      credentials: 'same-origin',
    })
      .then(response => response)
      .then(this.handleInvitationSuccess)
      .catch(null);
  };

  triggerLeaveChannel = e => {
    e.preventDefault();
    const id = e.target.dataset.content;
    fetch(`/chat_channel_memberships/${id}`, {
      method: 'DELETE',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({}),
      credentials: 'same-origin',
    })
      .then(response => response)
      .then(this.handleLeaveChannelSuccess)
      .catch(null);
  };

  handleLeaveChannelSuccess = () => {
    this.setState({ hasLeftChannel: true });
  };

  handleInvitationSuccess = response => {
    console.log(response); // eslint-disable-line no-console
  };

  userInList = (list, user) => {
    const keys = Object.keys(list);
    for (let i = 0; i < keys.length; i += 1) {
      const key = keys[i];
      if (user.id === list[key].id) {
        return true;
      }
    }
    return false;
  };

  render() {
    const channel = this.props.channel; // eslint-disable-line
    const users = Object.values(channel.channel_users).map(user => (
      <div className="channeldetails__user">
        <img
          className="channeldetails__userprofileimage"
          src={user.profile_image}
          alt={`${user.username} profile`}
          data-content="sidecar-user"
        />
        <a
          href={`/${user.username}`}
          style={{ color: user.darker_color, padding: '3px 0px' }}
          data-content="sidecar-user"
        >
          {user.name}
        </a>
      </div>
    ));
    let subHeader = '';
    if (users.length === 25) {
      subHeader = <h3>Recently Active Members</h3>;
    }
    let modSection = '';
    let searchedUsers = [];
    let pendingInvites = [];
    if (channel.channel_mod_ids.includes(window.currentUser.id)) {
      // eslint-disable-next-line
      searchedUsers = this.state.searchedUsers.map(user => {
        if (!this.userInList(channel.pending_users_select_fields, user)) {
          let invite = (
            <button
              type="button"
              onClick={this.triggerInvite}
              data-content={user.id}
            >
              Invite
            </button>
          );
          if (this.userInList(channel.channel_users, user)) {
            invite = (
              <span className="channel__member">
                is already in 
                {' '}
                <em>{channel.channel_name}</em>
              </span>
            );
          }
          return (
            <div className="channeldetails__searchedusers">
              <a href={user.path} target="_blank" rel="noopener noreferrer">
                <img src={user.user.profile_image_90} alt="profile_image" />
                @
                {user.user.username}
                {' '}
                -
                {/* prettier-ignore */} 
                {' '}
                {user.title}
              </a>
              {' '}
              {invite}
            </div>
          );
        }
      });
      pendingInvites = channel.pending_users_select_fields.map(user => (
        <div className="channeldetails__pendingusers">
          <a
            href={`/${user.username}`}
            target="_blank"
            rel="noopener noreferrer"
            data-content={`users/${user.id}`}
          >
            @
            {user.username}
            {' '}
            - 
            {' '}
            {user.name}
          </a>
        </div>
      ));
      modSection = (
        <div className="channeldetails__inviteusers">
          <h2>Invite Members</h2>
          <input onKeyUp={this.debouncedUserSearch} placeholder="Find users" />
          <div className="channeldetails__searchresults">{searchedUsers}</div>
          <h2>Pending Invites:</h2>
          {pendingInvites}
          <div style={{ marginTop: '10px' }}>
            Contact yo@dev.to for assistance.
          </div>
        </div>
      ); // eslint-disable-next-line
    } else if (this.state.hasLeftChannel) {
      modSection = (
        <div className="channeldetails__leftchannel">
          <h2>Danger Zone</h2>
          <h3>
            You have left this channel
            {' '}
            <span role="img" aria-label="emoji">
              😢😢😢
            </span>
          </h3>
          <h4>This may take a few minutes to be reflected in the sidebar</h4>
        </div>
      );
    } else {
      modSection = (
        <div className="channeldetails__leavechannel">
          <h2>Danger Zone</h2>
          <button
            type="button"
            onClick={this.triggerLeaveChannel}
            data-content={channel.id}
          >
            Leave Channel
          </button>
        </div>
      );
    }
    return (
      <div className="channeldetails">
        <h1 className="channeldetails__name">{channel.channel_name}</h1>
        <div
          className="channeldetails__description"
          style={{ marginBottom: '20px' }}
        >
          <em>{channel.description || ''}</em>
        </div>
        {subHeader}
        {users}
        {modSection}
      </div>
    );
  }
}

export default ChannelDetails;
