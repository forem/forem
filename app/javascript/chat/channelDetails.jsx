

import { h, Component } from 'preact';

export default class ChannelDetails extends Component {

  render() {
    const channel = this.props.channel
    const users = Object.values(channel.channel_users).map((user) => {
      return <div>
        <a
          href={'/'+user.username}
          style={{color:user.darker_color,padding: "3px 0px"}}
          data-content={`users/by_username?url=${user.username}`}
          >
          {user.name}
        </a>
      </div>
    });
    let subHeader = ''
    if (users.length === 80) {
      subHeader = <h3>Recently Active Members</h3>
    }
    return  <div>
              <h1>{channel.channel_name}</h1>
              {subHeader}
              {users}
            </div>
  }

}