import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { getTwilioToken } from '../actions';
const {connect, createLocalVideoTrack} = require('twilio-video');

export default class Video extends Component {
  constructor(props) {
    super(props);
    this.state = {
      leftPx: 200,
      topPx: 200,
      pageX: null,
      pageY: null,
      token: null,
      room: null,
      participants: []
    }
  }
  componentDidMount() {
    getTwilioToken('private-video-channel-'+this.props.activeChannelId, this.setupCallChannel)
  }

  componentWillUnmount() {
    this.state.room.disconnect();
  }

  setupCallChannel = (response) => {
    const component = this;
    connect(response.token,
      {
        name:`private-video-channel-${this.props.activeChannelId}`,
        audio: true,
        type: 'peer-to-peer',
        video: { width: 640 }
      }).then(function(room) {
      component.setState({token: response.token, room: room})
      createLocalVideoTrack().then(track => {
        let localMediaContainer = document.getElementById('videolocalscreen');
        localMediaContainer.appendChild(track.attach());
      });
      let roomParticipants = []
      room.participants.forEach(participant => {
        component.triggerRemoteJoin(participant);
        roomParticipants.push(participant);
      });
      component.setState({participants: roomParticipants})
      room.on('participantConnected', function(participant) {
        component.triggerRemoteJoin(participant);
        let roomParticipants = []
        room.participants.forEach(participant => {
          roomParticipants.push(participant);
        });
        component.setState({participants: roomParticipants})
        room.on('participantDisconnected', function(participant) {
          component.props.onExit()
        });
      })
    }, function(error) {
      document.getElementById('videoremotescreen').innerHTML = "";
        console.error('Unable to connect to Room: ' +  error.message);
    });
  }

  triggerRemoteJoin = (participant) => {
    // document.getElementById('videoremotescreen').innerHTML = ""
    participant.on('trackAdded', track => {
      document.getElementById('videoremotescreen').appendChild(track.attach());
    });
  }

  handleDrag = e => {
    if (!this.state.pageX) {
      this.setState({pageX:e.pageX,
        pageY: e.pageY,
        offsetDiffX: e.pageX - e.target.offsetLeft,
        offsetDiffY: e.pageY - e.target.offsetTop,
      })
    } else if (e.pageX != 0){
      this.setState({
        leftPx: this.state.pageX + e.pageX - this.state.pageX - this.state.offsetDiffX,
        topPx: this.state.pageY + e.pageY - this.state.pageY - this.state.offsetDiffY
      })
    } else if (e.pageX === 0) {
      this.setState({pageX:null,
        pageY: null,
        offsetDiffX: null,
        offsetDiffY: null,
      })
    }
  }

  render() {
    return (
      <div
        className="chat__videocall"
          id="chat__videocall"
          draggable="true"
          onDrag={this.handleDrag}
          style={{left:this.state.leftPx+'px', top: this.state.topPx+'px'}}
          >
        <div id="videoremotescreen" class={'chat__remotevideoscreen-'+this.state.participants.length}></div>
        <div className="chat__localvideoscren" id="videolocalscreen"></div>
        <button className="chat__videocallexitbutton" onClick={this.props.onExit}>
          ×
        </button>
      </div>
    )
  }
}









