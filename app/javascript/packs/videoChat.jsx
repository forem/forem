import { h, Component, render } from 'preact';
import PropTypes from 'prop-types';

const root = document.getElementById('chat')


export default class VideoChat extends Component {

  componentDidMount() {
    this.setupCallChannel(root.dataset.token)
  }

  setupCallChannel = token => {
    const component = this;
    const activeChannelId = root.dataset.channel
    console.log()
    import('twilio-video').then(({ connect, createLocalVideoTrack }) => {
      connect(
        token,
        {
          name: `private-video-channel-${activeChannelId}`,
          audio: true,
          type: 'peer-to-peer',
          video: { width: 640 },
        },
      ).then(
        function onConnectSuccess(room) {
          console.log(room)
          component.setState({ token: token, room });
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
            console.log('participant joined')
            component.triggerRemoteJoin(participant);
            room.participants.forEach(p => {
              roomParticipants.push(p);
            });
            component.setState({ participants: roomParticipants });
            room.on(
              'participantDisconnected',
              function onParticipantDisconnected() {
                console.log('disconnected')
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
    participant.on('trackSubscribed', track => {
      console.log(track)
      if (!document.getElementById(`${track.kind}-${track.id}`)) {
        const trackDiv = document.createElement('div');
        trackDiv.className = `chat__videocalltrackdiv--${track.kind}`;
        trackDiv.id = participant.sid;
        trackDiv.appendChild(track.attach());
        document.getElementById('videoremotescreen').appendChild(trackDiv);
        document.getElementById(
          'videoremotescreen',
        ).lastChild.id = `${track.kind}-${track.sid}`;
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


  render() {

    return <div>
             <div id="videoremotescreen"></div>
             <div id="videolocalscreen"></div>
           </div>
  }

}


render(<VideoChat />, root, root.firstElementChild);

