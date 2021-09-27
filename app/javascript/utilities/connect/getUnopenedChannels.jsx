import { h, render, Component } from 'preact';
import PropTypes from 'prop-types';
import { setupPusher } from './pusher';

/* global userData */

class UnopenedChannelNotice extends Component {
  propTypes = {
    pusherKey: PropTypes.Object,
  };

  static defaultProps = {
    pusherKey: undefined,
  };

  constructor(props) {
    super(props);
    this.state = {
      visible: false,
      unopenedChannels: [],
    };
  }

  componentDidMount() {
    const { pusherKey } = this.props;
    const { appDomain } = document.body.dataset;
    setupPusher(pusherKey, {
      channelId: `private-message-notifications--${appDomain}-${window.currentUser.id}`,
      messageCreated: this.receiveNewMessage,
      messageDeleted: this.removeMessage,
      messageEdited: this.updateMessage,
      mentioned: this.mentionedMessage,
      messageOpened: this.messageOpened,
    });
    this.fetchUnopenedChannel(this.updateMessageNotification);

    if(document.getElementById('connect-link')) {
      document.getElementById('connect-link').onclick = () => {
        // Hack, should probably be its own component in future
        document.getElementById('connect-number').classList.add('hidden');
        this.setState({ visible: false });
      };
    }
  }

  updateMessageNotification = (unopenedChannels) => {
    const number = document.getElementById('connect-number');
    this.setState({ unopenedChannels });
    if (unopenedChannels.length > 0) {
      if (unopenedChannels[0].adjusted_slug === `@${userData().username}`) {
        return;
      }
      number.classList.remove('hidden');
      number.innerHTML = unopenedChannels.length;
      document.getElementById(
        'connect-link',
      ).href = `/connect/${unopenedChannels[0].adjusted_slug}`;
      InstantClick.preload(
        document.getElementById('connect-link').href,
        'force',
      );
    } else {
      number.classList.add('hidden');
    }
  };

  removeMessage = () => {};

  updateMessage = () => {};

  mentionedMessage = (e) => {
    if (window.location.pathname.startsWith('/connect')) {
      return;
    }

    this.setState((prevState) => ({
      unopenedChannels: prevState.unopenedChannels.map((unopenedChannel) =>
        unopenedChannel.adjusted_slug === e.chat_channel_adjusted_slug
          ? { ...unopenedChannel, request_type: 'mentioned' }
          : unopenedChannel,
      ),
      visible: true,
    }));

    this.hideNotice();
  };

  messageOpened = (e) => {
    const { unopenedChannels } = this.state;
    if (
      !window.location.pathname.startsWith('/connect') ||
      !window.location.pathname.includes(e.adjusted_slug)
    )
      return;
    this.updateMessageNotification(
      unopenedChannels.filter(
        (unopenedChannel) => unopenedChannel.adjusted_slug !== e.adjusted_slug,
      ),
    );
  };

  receiveNewMessage = (e) => {
    if (
      e.user_id === window.currentUser.id ||
      (window.location.pathname.startsWith('/connect') &&
        e.user_id === window.currentUser.id &&
        e.channel_type !== 'direct') ||
      window.location.pathname.includes(e.chat_channel_adjusted_slug)
    ) {
      return;
    }
    const { unopenedChannels } = this.state;
    const newObj = { adjusted_slug: e.chat_channel_adjusted_slug };

    const ifMessageExist = unopenedChannels.some(
      (channel) => channel.adjusted_slug === newObj.adjusted_slug,
    );

    if (
      !ifMessageExist &&
      newObj.adjusted_slug !== `@${window.currentUser.username}`
    ) {
      unopenedChannels.push(newObj);
    }
    if (ifMessageExist) {
      const index = unopenedChannels.findIndex(
        (channel) => channel.adjusted_slug === newObj.adjusted_slug,
      );
      unopenedChannels[index].notified = false;
    }

    if (!window.location.pathname.startsWith('/connect')) {
      this.setState({
        visible:
          unopenedChannels.length > 0 &&
          e.user_id !== window.currentUser.id &&
          e.channel_type === 'direct',
      });
    }
    this.updateMessageNotification(unopenedChannels);
    this.hideNotice();
  };

  handleClick = () => {
    this.hideNotice();
  };

  hideNotice = () => {
    setTimeout(() => {
      this.setState((prevState) => ({
        unopenedChannels: prevState.unopenedChannels.map((unopenedChannel) =>
          !unopenedChannel.notified
            ? { ...unopenedChannel, notified: true }
            : unopenedChannel,
        ),
        visible: false,
      }));
    }, 7500);
  };

  fetchUnopenedChannel = (successCb) => {
    fetch('/chat_channels?state=unopened', {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      credentials: 'same-origin',
    })
      .then((response) => response.json())
      .then(successCb);
  };

  render() {
    const { visible, unopenedChannels } = this.state;
    if (visible && unopenedChannels.some((channel) => !channel.notified)) {
      const message = unopenedChannels.map((channel) => {
        if (channel.notified) return null;
        return (
          <div key={channel.id}>
            {channel.request_type === 'mentioned'
              ? 'You got mentioned in'
              : 'New Message from'}{' '}
            <a
              href={`/connect/${channel.adjusted_slug}`}
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
          </div>
        );
      });

      return (
        <a
          href={`/connect/${unopenedChannels[0].adjusted_slug}`}
          onClick={this.handleClick}
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
          {message}
        </a>
      );
    }

    return '';
  }
}

export function getUnopenedChannels() {
  if (window.frameElement) {
    return;
  }
  render(
    <UnopenedChannelNotice pusherKey={document.body.dataset.pusherKey} />,
    document.getElementById('message-notice'),
  );
}
