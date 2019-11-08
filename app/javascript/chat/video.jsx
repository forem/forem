import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { getTwilioToken } from './actions';

/**
 * TODO: Instead of calling this function in render, use jsx (<VideoControlButton />).
 */
function VideoControlButton({ btnClassName, btnClickCallback, btnLabel }) {
  return (
    <button type="button" className={btnClassName} onClick={btnClickCallback}>
      {btnLabel}
    </button>
  );
}

VideoControlButton.propTypes = {
  btnClassName: PropTypes.string.isRequired,
  btnClickCallback: PropTypes.func.isRequired,
  btnLabel: PropTypes.string.isRequired,
};

export default class Video extends Component {
  static propTypes = {
    activeChannelId: PropTypes.string.isRequired,
    onToggleSound: PropTypes.func.isRequired,
    onToggleVideo: PropTypes.func.isRequired,
    onExit: PropTypes.func.isRequired,
    soundOn: PropTypes.bool.isRequired,
    videoOn: PropTypes.bool.isRequired,
  };

  constructor(props) {
    super(props);
    let leftPx = 40;
    let topPx = 70;
    if (window.innerWidth > 1500) {
      leftPx = window.innerWidth / 5 + 200;
      topPx = window.innerHeight / 10;
    } else if (window.innerWidth > 641) {
      leftPx = window.innerWidth / 6;
      topPx = window.innerHeight / 10;
    }
    this.state = {
      leftPx,
      topPx,
      pageX: null,
      pageY: null,
      room: null,
      participants: [],
    };
  }

  componentDidMount() {
    const { activeChannelId } = this.props;
    getTwilioToken(
      `private-video-channel-${activeChannelId}`,
      this.setupCallChannel,
    );
  }

  componentWillUnmount() {
    const { room } = this.state;
    room.disconnect();
  }

  setupCallChannel = response => {
    const component = this;
    const { activeChannelId } = this.props;
    import('twilio-video').then(({ connect, createLocalVideoTrack }) => {
      connect(
        response.token,
        {
          name: `private-video-channel-${activeChannelId}`,
          audio: true,
          type: 'peer-to-peer',
          video: { width: 640 },
        },
      ).then(
        function onConnectSuccess(room) {
          component.setState({ token: response.token, room });
          createLocalVideoTrack().then(track => {
            const localMediaContainer = document.getElementById(
              'videolocalscreen',
            );
            localMediaContainer.appendChild(track.attach());
          });
          const roomParticipants = [];
          room.participants.forEach(participant => {
            component.triggerRemoteJoin(participant);
            roomParticipants.push(participant);
          });
          component.setState({ participants: roomParticipants });
          room.on('participantConnected', function onParticipantConnected(
            participant,
          ) {
            component.props.onParticipantChange(room.participants);
            component.triggerRemoteJoin(participant);
            room.participants.forEach(p => {
              roomParticipants.push(p);
            });
            component.setState({ participants: roomParticipants });
            room.on(
              'participantDisconnected',
              function onParticipantDisconnected() {
                component.props.onParticipantChange(room.participants);
              },
            );
            participant.on('dominantSpeakerChanged', dominantSpeaker => {
              // eslint-disable-next-line no-console
              console.log(
                'The new dominant speaker in the Room is:',
                dominantSpeaker,
              );
            });
          });
        },
        function onConnectFailure(error) {
          document.getElementById('videoremotescreen').innerHTML = '';
          // eslint-disable-next-line no-console
          console.error(`Unable to connect to Room: ${error.message}`);
        },
      );
    });
  };

  triggerRemoteJoin = participant => {
    participant.on('trackAdded', track => {
      if (!document.getElementById(`${track.kind}-${track.id}`)) {
        const trackDiv = document.createElement('div');
        trackDiv.className = `chat__videocalltrackdiv--${track.kind}`;
        trackDiv.appendChild(track.attach());
        document.getElementById('videoremotescreen').appendChild(trackDiv);
        document.getElementById(
          'videoremotescreen',
        ).lastChild.id = `${track.kind}-${track.id}`;
      }
    });
    participant.on('trackRemoved', track => {
      if (document.getElementById(track.id)) {
        document.getElementById(track.id).outerHTML = '';
      }
    });
    // participant.on('trackDisabled', track => {
    //   console.log('disabled')
    //   console.log('TODO: Show track status on video')
    //   console.log(track.mediaStreamTrack.id)
    // });
    // participant.on('trackEnabled', track => {
    //   console.log('enabled')
    //   console.log('TODO: Show track status on video')
    //   console.log(track.mediaStreamTrack.id)
    // });
  };

  handleDrag = e => {
    const { pageX, offsetDiffX, pageY, offsetDiffY } = this.state;
    if (!pageX) {
      this.setState({
        pageX: e.pageX,
        pageY: e.pageY,
        offsetDiffX: e.pageX - e.target.offsetLeft,
        offsetDiffY: e.pageY - e.target.offsetTop,
      });
    } else if (e.pageX !== 0) {
      this.setState({
        leftPx: pageX + e.pageX - pageX - offsetDiffX,
        topPx: pageY + e.pageY - pageY - offsetDiffY,
      });
    } else if (e.pageX === 0) {
      this.setState({
        pageX: null,
        pageY: null,
        offsetDiffX: null,
        offsetDiffY: null,
      });
    }
  };

  toggleSound = () => {
    const { room } = this.state;
    const { onToggleSound } = this.props;
    if (room) {
      room.localParticipant.audioTracks.forEach(track => {
        if (track.isEnabled) {
          track.disable();
        } else {
          track.enable();
        }
      });
    }
    onToggleSound();
  };

  toggleVideo = () => {
    const { room } = this.state;
    const { onToggleVideo } = this.props;
    if (room) {
      room.localParticipant.videoTracks.forEach(track => {
        if (track.isEnabled) {
          track.disable();
        } else {
          track.enable();
        }
      });
    }
    onToggleVideo();
  };

  render() {
    const { topPx, leftPx, participants } = this.state;
    const { onExit, soundOn, videoOn } = this.props;
    return (
      <div
        className="chat__videocall"
        id="chat__videocall"
        draggable="true"
        onDrag={this.handleDrag}
        style={{ left: `${leftPx}px`, top: `${topPx}px` }}
      >
        <div
          id="videoremotescreen"
          className={`chat__remotevideoscreen-${participants.length}`}
        />
        <div className="chat__localvideoscren" id="videolocalscreen" />
        {VideoControlButton({
          btnClassName: 'chat__videocallexitbutton',
          btnClickCallback: onExit,
          btnLabel: '×',
        })}
        {VideoControlButton({
          btnClassName: 'chat__videocallcontrolbutton',
          btnClickCallback: this.toggleSound,
          btnLabel: soundOn ? 'Mute' : 'UnMute',
        })}
        {VideoControlButton({
          btnClassName:
            'chat__videocallcontrolbutton chat__videocallcontrolbutton--videoonoff',
          btnClickCallback: this.toggleVideo,
          btnLabel: videoOn ? 'Turn Off Video' : 'Turn On Video',
        })}
      </div>
    );
  }
}
