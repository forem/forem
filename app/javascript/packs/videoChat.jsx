const { createLocalVideoTrack, connect } = require('twilio-video');
const root = document.getElementById('videochat');
const muteButton = document.getElementById('mute-toggle');
const videoToggleButton = document.getElementById('videohide-toggle');
let numConnected = 0;
connect(root.dataset.token, { name: 'room-name', audio: true, type: 'peer-to-peer', video: { width: 640 } }).then(room => {
  room.participants.forEach(participantConnected);
  room.on('participantConnected', participantConnected);

  room.on('participantDisconnected', participantDisconnected);
  room.once('disconnected', error => room.participants.forEach(participantDisconnected));
  console.log(room.participants.length)
  muteButton.onclick = function(e) {
    e.preventDefault();
    room.localParticipant.audioTracks.forEach(function(trackPub) {
      if (muteButton.dataset.muted === 'true') {
        muteButton.dataset.muted = 'false'
        muteButton.classList.remove('active');
        trackPub.track.enable();
      } else {
        muteButton.dataset.muted = 'true'
        muteButton.classList.add('active');
        trackPub.track.disable();
      }
    });  
  }

  videoToggleButton.onclick = function(e) {
    e.preventDefault();
    room.localParticipant.videoTracks.forEach(function(trackPub) {
      if (videoToggleButton.dataset.hidden === 'true') {
        videoToggleButton.dataset.hidden = 'false'
        videoToggleButton.classList.remove('active');
        trackPub.track.enable();
      } else {
        videoToggleButton.dataset.hidden = 'true'
        videoToggleButton.classList.add('active');
        trackPub.track.disable();
      }
    });  
  }

});


createLocalVideoTrack().then(track => {
  const localMediaContainer = document.getElementById('local-media');
  localMediaContainer.appendChild(track.attach());

});


function participantConnected(participant) {
  const div = document.createElement('div');
  div.id = participant.sid;
  div.className = "individual-video"
  div.innerHTML = '<div class="participant-name">'+ participant.identity + '</div>'

  participant.on('trackSubscribed', track => trackSubscribed(div, track));
  participant.on('trackUnsubscribed', trackUnsubscribed);

  participant.tracks.forEach(publication => {
    if (publication.isSubscribed) {
      trackSubscribed(div, publication.track);
    }
  });
  root.appendChild(div);
  numConnected += 1;
  let gridStyle = 'one-per';
  if (numConnected > 2) {
    gridStyle = 'two-per';
  }
  if (numConnected > 6) {
    gridStyle = 'three-per';
  }
  if (numConnected > 9) {
    gridStyle = 'four-per';
  }
  root.className = 'video-chat-wrapper video-chat-wrapper-num-' + gridStyle;
}

function participantDisconnected(participant) {
  console.log('Participant "%s" disconnected', participant.identity);
  document.getElementById(participant.sid).remove();
}

function trackSubscribed(div, track) {
  div.appendChild(track.attach());
}

function trackUnsubscribed(track) {
  track.detach().forEach(element => element.remove());
}

