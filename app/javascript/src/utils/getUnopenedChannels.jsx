import { h, render, Component } from 'preact';
import PropTypes from 'prop-types';
import setupPusher from './pusher';

class UnopenedChannelNotice extends Component {
  static defaultProps = {
    unopenedChannels: undefined,
    pusherKey: undefined,
  };

  propTypes = {
    unopenedChannels: PropTypes.Object,
    pusherKey: PropTypes.Object,
  };

  constructor(props) {
    super(props);
    const { unopenedChannels } = this.props;
    const visible = unopenedChannels.length > 0;
    this.state = {
      visible,
      unopenedChannels,
    };
  }

  componentDidMount() {
    const { pusherKey } = this.props;
    setupPusher(pusherKey, {
      channelId: `private-message-notifications-${window.currentUser.id}`,
      messageCreated: this.receiveNewMessage,
    });
    const component = this;
    document.getElementById('connect-link').onclick = () => {
      // Hack, should probably be its own component in future
      document.getElementById('connect-number').classList.remove('showing');
      component.setState({ visible: false });
    };
  }

  receiveNewMessage = e => {
    if (window.location.pathname.startsWith('/connect')) {
      return;
    }
    const { unopenedChannels } = this.state;
    const newObj = { adjusted_slug: e.chat_channel_adjusted_slug };
    if (
      unopenedChannels.filter(obj => obj.adjusted_slug === newObj.adjusted_slug)
        .length === 0 &&
      newObj.adjusted_slug !== `@${window.currentUser.username}`
    ) {
      unopenedChannels.push(newObj);
    }
    this.setState({
      visible:
        unopenedChannels.length > 0 && e.user_id !== window.currentUser.id,
      unopenedChannels,
    });

    const number = document.getElementById('connect-number');
    number.classList.add('showing');
    number.innerHTML = unopenedChannels.length;
    const component = this;
    if (unopenedChannels.length === 0) {
      number.classList.remove('showing');
    } else {
      document.getElementById(
        'connect-link',
      ).href = `/connect/${unopenedChannels[0].adjusted_slug}`;
    }
    setTimeout(() => {
      component.setState({ visible: false });
    }, 7500);
  };

  handleClick = () => {
    document.getElementById('connect-number').classList.remove('showing');
    this.setState({ visible: false });
  };

  render() {
    const { visible, unopenedChannels } = this.state;
    if (visible) {
      const channels = unopenedChannels.map(channel => {
        return (
          <a
            href={`/connect/${unopenedChannels[0].adjusted_slug}`}
            style={{
              background: '#66e2d5',
              color: 'black',
              border: '1px solid black',
              padding: '2px 7px',
              display: 'inline-block',
              margin: '3px 6px',
              borderRadius: '3px',
            }}
          >
            {channel.adjusted_slug}
          </a>
        );
      });
      return (
        <a
          onClick={this.handleClick}
          href={`/connect/${unopenedChannels[0].adjusted_slug}`}
          style={{
            position: 'fixed',
            zIndex: '200',
            top: '44px',
            right: 0,
            left: 0,
            background: '#66e2d5',
            borderBottom: '1px solid black',
            color: 'black',
            fontWeight: 'bold',
            textAlign: 'center',
            fontSize: '17px',
            opacity: '0.94',
            padding: '19px 5px 14px',
          }}
        >
          New Message from {channels}
        </a>
      );
    }

    return '';
  }
}

function manageChannel(json) {
  const number = document.getElementById('connect-number');
  if (json.length > 0) {
    number.classList.add('showing');
    number.innerHTML = json.length;
    document.getElementById(
      'connect-link',
    ).href = `/connect/${json[0].adjusted_slug}`; // Jump the user directly to the channel where appropriate
  } else {
    number.classList.remove('showing');
  }
}

export default function getUnopenedChannels() {
  render(
    <UnopenedChannelNotice
      unopenedChannels={[]}
      pusherKey={document.body.dataset.pusherKey}
    />,
    document.getElementById('message-notice'),
  );
  if (window.location.pathname.startsWith('/connect')) return;
  fetch('/chat_channels?state=unopened', {
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(json => {
      manageChannel(json);
    });
}
