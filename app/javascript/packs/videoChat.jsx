const { createLocalVideoTrack, connect } = require('twilio-video');
const root = document.getElementById('chat');
const muteButton = document.getElementById('mute-toggle');
const videoToggleButton = document.getElementById('videohide-toggle')
connect(root.dataset.token, { name: 'room-name', audio: true, type: 'peer-to-peer', video: { width: 640 } }).then(room => {
  room.participants.forEach(participantConnected);
  room.on('participantConnected', participantConnected);

  room.on('participantDisconnected', participantDisconnected);
  room.once('disconnected', error => room.participants.forEach(participantDisconnected));

  muteButton.onclick = function(e) {
    e.preventDefault();
    room.localParticipant.audioTracks.forEach(function(trackPub) {
      if (muteButton.dataset.muted === 'true') {
        muteButton.dataset.muted = 'false'
        trackPub.track.enable();
      } else {
        muteButton.dataset.muted = 'true'
        trackPub.track.disable();
      }
    });  
  }

  videoToggleButton.onclick = function(e) {
    e.preventDefault();
    room.localParticipant.videoTracks.forEach(function(trackPub) {
      if (videoToggleButton.dataset.hidden === 'true') {
        videoToggleButton.dataset.hidden = 'false'
        trackPub.track.enable();
      } else {
        videoToggleButton.dataset.hidden = 'true'
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

