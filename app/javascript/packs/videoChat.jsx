const { createLocalVideoTrack, connect } = require('twilio-video');
const root = document.getElementById('videochat');
const remoteMedia = document.getElementById('remote-media');
const muteButton = document.getElementById('mute-toggle');
const videoToggleButton = document.getElementById('videohide-toggle');
const localMediaContainer = document.getElementById('local-media');
const roomType = document.getElementById('room-type').dataset.type; //Group

connect(root.dataset.token, {
  name: 'room-name',
  audio: true,
  type: roomType,
  video: { width: 800 },
}).then((room) => {
  room.participants.forEach(participantConnected);
  room.on('participantConnected', participantConnected);

  room.on('participantDisconnected', participantDisconnected);
  room.once('disconnected', (_error) =>
    room.participants.forEach(participantDisconnected),
  );
  muteButton.onclick = function (e) {
    e.preventDefault();
    room.localParticipant.audioTracks.forEach(function (trackPub) {
      if (muteButton.dataset.muted === 'true') {
        muteButton.dataset.muted = 'false';
        muteButton.classList.remove('crayons-btn--danger');
        muteButton.innerHTML = 'Mute';
        trackPub.track.enable();
      } else {
        muteButton.dataset.muted = 'true';
        muteButton.classList.add('crayons-btn--danger');
        muteButton.innerHTML = 'Unmute';
        trackPub.track.disable();
      }
    });
  };

  videoToggleButton.onclick = function (e) {
    e.preventDefault();
    room.localParticipant.videoTracks.forEach(function (trackPub) {
      if (videoToggleButton.dataset.hidden === 'true') {
        videoToggleButton.dataset.hidden = 'false';
        videoToggleButton.classList.remove('crayons-btn--danger');
        videoToggleButton.innerHTML = 'Hide';
        localMediaContainer.classList.remove('video-hidden');
        trackPub.track.enable();
      } else {
        videoToggleButton.dataset.hidden = 'true';
        videoToggleButton.classList.add('crayons-btn--danger');
        videoToggleButton.innerHTML = 'Unhide';
        localMediaContainer.classList.add('video-hidden');
        trackPub.track.disable();
      }
    });
  };
});

createLocalVideoTrack().then((track) => {
  localMediaContainer.appendChild(track.attach());
  document.getElementById('video-controls').classList.add('showing');
});

function participantConnected(participant) {
  const numExistingDivs = document.getElementsByClassName('individual-video')
    .length;
  const div = document.createElement('div');
  div.id = participant.sid;
  div.className = `individual-video${
    numExistingDivs > 3 ? ' one-of-many-videos' : ''
  }`;
  div.innerHTML = `<div class="participant-info">\
      <div class="participant-name">${participant.identity}</div>\
      <div class="disabled-audio-indicator">audio off</div>\
      <div class="disabled-video-indicator">video off</div>\
    </div>`;

  participant.on('trackSubscribed', (track) => trackSubscribed(div, track));
  participant.on('trackUnsubscribed', trackUnsubscribed);

  participant.on('trackDisabled', (track) => trackDisabled(div, track));
  participant.on('trackEnabled', (track) => trackEnabled(div, track));

  participant.tracks.forEach((publication) => {
    if (publication.isSubscribed) {
      trackSubscribed(div, publication.track);
    }
  });
  remoteMedia.appendChild(div);
}

function participantDisconnected(participant) {
  document.getElementById(participant.sid).remove();
}

function trackSubscribed(div, track) {
  div.appendChild(track.attach());
  if (!track.isEnabled) {
    if (track.kind === 'video') {
      div.classList.add('disabled-video');
    } else {
      div.classList.add('disabled-audio');
    }
  }
}

function trackUnsubscribed(track) {
  track.detach().forEach((element) => element.remove());
}

function trackDisabled(div, track) {
  if (track.kind === 'video') {
    div.classList.add('disabled-video');
  } else {
    div.classList.add('disabled-audio');
  }
}

function trackEnabled(div, track) {
  if (track.kind === 'video') {
    div.classList.remove('disabled-video');
  } else {
    div.classList.remove('disabled-audio');
  }
}

if (navigator.userAgent === 'DEV-Native-ios') {
  root.innerHTML =
    '<h2 class="platform-unavailable-message">This feature is not yet available on iPhone</h2>';
}
