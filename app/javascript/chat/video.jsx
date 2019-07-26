import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { getTwilioToken } from './actions';

export default class Video extends Component {
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
      token: null,
      room: null,
      participants: [],
    };
  }

  componentDidMount() {
    getTwilioToken(
      `private-video-channel-${this.props.activeChannelId}`,
      this.setupCallChannel,
    );
  }

  componentWillUnmount() {
    this.state.room.disconnect();
  }

  setupCallChannel = response => {
    const component = this;
    import('twilio-video').then(({ connect, createLocalVideoTrack }) => {
      connect(
        response.token,
        {
          name: `private-video-channel-${this.props.activeChannelId}`,
          audio: true,
          type: 'peer-to-peer',
          video: { width: 640 },
        },
      ).then(
        function(room) {
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
          room.on('participantConnected', function(participant) {
            component.props.onParticipantChange(room.participants);
            component.triggerRemoteJoin(participant);
            room.participants.forEach(p => {
              roomParticipants.push(p);
            });
            component.setState({ participants: roomParticipants });
            room.on('participantDisconnected', function() {
              component.props.onParticipantChange(room.participants);
            });
            participant.on('dominantSpeakerChanged', participant => {
              console.log(
                'The new dominant speaker in the Room is:',
                participant,
              );
            });
          });
        },
        function(error) {
          document.getElementById('videoremotescreen').innerHTML = '';
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
    if (!this.state.pageX) {
      this.setState({
        pageX: e.pageX,
        pageY: e.pageY,
        offsetDiffX: e.pageX - e.target.offsetLeft,
        offsetDiffY: e.pageY - e.target.offsetTop,
      });
    } else if (e.pageX != 0) {
      this.setState({
        leftPx:
          this.state.pageX +
          e.pageX -
          this.state.pageX -
          this.state.offsetDiffX,
        topPx:
          this.state.pageY +
          e.pageY -
          this.state.pageY -
          this.state.offsetDiffY,
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
    if (room) {
      room.localParticipant.audioTracks.forEach(track => {
        if (track.isEnabled) {
          track.disable();
        } else {
          track.enable();
        }
      });
    }
    this.props.onToggleSound();
  };

  toggleVideo = () => {
    const { room } = this.state;
    if (room) {
      room.localParticipant.videoTracks.forEach(track => {
        if (track.isEnabled) {
          track.disable();
        } else {
          track.enable();
        }
      });
    }
    this.props.onToggleVideo();
  };

  render() {
    return (
      <div
        className="chat__videocall"
        id="chat__videocall"
        draggable="true"
        onDrag={this.handleDrag}
        style={{ left: `${this.state.leftPx}px`, top: `${this.state.topPx}px` }}
      >
        <div
          id="videoremotescreen"
          className={`chat__remotevideoscreen-${this.state.participants.length}`}
        />
        <div className="chat__localvideoscren" id="videolocalscreen" />
        <button
          className="chat__videocallexitbutton"
          onClick={this.props.onExit}
        >
          ×
        </button>
        <button
          className="chat__videocallcontrolbutton"
          onClick={this.toggleSound}
        >
          {this.props.soundOn ? 'Mute' : 'UnMute'}
        </button>
        <button
          className="chat__videocallcontrolbutton chat__videocallcontrolbutton--videoonoff"
          onClick={this.toggleVideo}
        >
          {this.props.videoOn ? 'Turn Off Video' : 'Turn On Video'}
        </button>
      </div>
    );
  }
}
