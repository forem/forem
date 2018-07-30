import { h, Component } from 'preact';

const algoliaId = document.querySelector("meta[name='algolia-public-id']")
  .content;
const algoliaKey = document.querySelector("meta[name='algolia-public-key']")
  .content;
const env = document.querySelector("meta[name='environment']").content;
const client = algoliasearch(algoliaId, algoliaKey);
const index = client.initIndex(`searchables_${  env}`);

export default class ChannelDetails extends Component {
  constructor(props) {
    super(props);
    this.state = {
      searchedUsers: [],
      invitations: [],
      hasLeftChannel: false,
    };
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
      index.search(query, filters).then((content) => {
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

  handleLeaveChannelSuccess = response => {
    this.setState({ hasLeftChannel: true });
  };

  handleInvitationSuccess = response => {
    console.log(response);
  };

  render() {
    const channel = this.props.channel;
    const users = Object.values(channel.channel_users).map(user => (
      <div>
        <a
          href={`/${  user.username}`}
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
      searchedUsers = this.state.searchedUsers.map(user => (
        <div>
          <a href={user.path} target="_blank">
            {user.title}
          </a>{' '}
          <button onClick={this.triggerInvite} data-content={user.id}>
              Invite
          </button>
        </div>
        ));
      pendingInvites = channel.pending_users_select_fields.map(user => (
        <div>
          <a
            href={`/${  user.username}`}
            target="_blank"
            data-content={`users/${  user.id}`}
          >
              @{user.username} - {user.name}
          </a>
        </div>
        ));
      modSection = (
        <div>
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
      );
    } else if (this.state.hasLeftChannel) {
        modSection = (
          <div>
            <h2>Danger Zone</h2>
            <h3>You have left this channel 😢😢😢</h3>
            <h4>It may not be immediately in the sidebar</h4>
            <p>
              Contact the admins at <a href="mailto:yo@dev.to">yo@dev.to</a> if
              this was a mistake
            </p>
          </div>
        );
      } else {
        modSection = (
          <div>
            <h2>Danger Zone</h2>
            <button
              onClick={this.triggerLeaveChannel}
              data-content={channel.id}
            >
              Leave Channel.
            </button>
          </div>
        );
      }
    return (
      <div>
        <h1>{channel.channel_name}</h1>
        {subHeader}
        <div style={{ marginBottom: '20px' }}>
          <em>{channel.description || ''}</em>
        </div>
        {users}
        {modSection}
      </div>
    );
  }
}
