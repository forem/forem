import { h, Component } from 'preact';
import PropTypes from 'prop-types';

class ChannelDetails extends Component {
  static propTypes = {
    channel: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  };

  constructor(props) {
    super(props);

    this.state = {
      searchedUsers: [],
      // invitations: [],
      hasLeftChannel: false,
    };

    const algoliaId = document.querySelector("meta[name='algolia-public-id']")
      .content;
    const algoliaKey = document.querySelector("meta[name='algolia-public-key']")
      .content;
    const env = document.querySelector("meta[name='environment']").content;
    const client = algoliasearch(algoliaId, algoliaKey); // eslint-disable-line no-undef
    this.index = client.initIndex(`searchables_${env}`);
  }

  triggerUserSearch = e => {
    const component = this;
    const query = e.target.value;
    const filters = {
      hitsPerPage: 20,
      attributesToRetrieve: ['id', 'title', 'path'],
      attributesToHighlight: [],
      filters: 'class_name:User',
    };
    if (query.length > 0) {
      this.index.search(query, filters).then(content => {
        component.setState({ searchedUsers: content.hits });
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

  render() {
    const channel = this.props.channel; // eslint-disable-line
    const users = Object.values(channel.channel_users).map(user => (
      <div className="channeldetails__user">
        <a
          href={`/${user.username}`}
          style={{ color: user.darker_color, padding: '3px 0px' }}
          data-content={`users/by_username?url=${user.username}`}
        >
          {user.name}
        </a>
      </div>
    ));
    let subHeader = '';
    if (users.length === 80) {
      subHeader = <h3>Recently Active Members</h3>;
    }
    let modSection = '';
    let searchedUsers = [];
    let pendingInvites = [];
    if (channel.channel_mod_ids.includes(window.currentUser.id)) {
      // eslint-disable-next-line
      searchedUsers = this.state.searchedUsers.map(user => {
        let invite = (
          <button
            type="button"
            onClick={this.triggerInvite}
            data-content={user.id}
          >
            Invite
          </button>
        );
        if (channel.channel_users.includes(user)) {
          invite = (
            <span>
              is already in
              {channel.name}
            </span>
          );
        } else if (channel.pending_users_select_fields.includes(user)) {
          invite = (
            <span>
              has already been invited to
              {channel.name}
            </span>
          );
        }
        return (
          <div className="channeldetails__searchedusers">
            <a href={user.path} target="_blank" rel="noopener noreferrer">
              <img alt="profile_image" src={user.profile_image} />
@
              {user.username}
              {' '}
-
              {' '}
              {user.name}
            </a>
            {' '}
            {invite}
          </div>
        );
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
          <input onKeyUp={this.triggerUserSearch} placeholder="Find users" />
          {searchedUsers}
          <h2>Pending Invites:</h2>
          {pendingInvites}
          <div style={{ marginTop: '10px' }}>
            All functionality is early beta. Contact us if you need help with
            anything.
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
          <h4>It may not be immediately in the sidebar</h4>
          <p>
            Contact the admins at
            {' '}
            <a href="mailto:yo@dev.to">yo@dev.to</a>
            {' '}
if
            this was a mistake
          </p>
        </div>
      );
    } else {
      modSection = (
        <div className="channeldetails__leavechannel">
          <h2>Danger Zone</h2>
          <button
            type="button"
            Click={this.triggerLeaveChannel}
            data-content={channel.id}
          >
            Leave Channel.
          </button>
        </div>
      );
    }
    return (
      <div className="channeldetails">
        <h1 className="channeldetails__name">{channel.channel_name}</h1>
        {subHeader}
        <div
          className="channeldetails__description"
          style={{ marginBottom: '20px' }}
        >
          <em>{channel.description || ''}</em>
        </div>
        {users}
        {modSection}
      </div>
    );
  }
}

export default ChannelDetails;
