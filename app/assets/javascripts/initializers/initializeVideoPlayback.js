/**
 * This script hunts for video tags and initializes the correct player
 * depending on the platform:
 * - web: jwplayer
 * - iOS/Android: Native player
 *
 * Once jwplayer is initialized there's no follow up actions to be taken.
 * Mobile Native players send back information into the DOM in order to
 * interact and update the UI, therefore a MutationObserver is registered.
 */

/* eslint no-use-before-define: 0 */
/* eslint no-param-reassign: 0 */
/* eslint no-useless-escape: 0 */
/* global jwplayer, ahoy, Runtime */

function initializeVideoPlayback() {
  var currentTime = '0';
  var deviceType = 'web';
  var lastEvent = '';

  function getById(name) {
    return document.getElementById(name);
  }

  function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
      results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
  }

  function timeToSeconds(hms) {
    var a;
    if (hms.length < 3) {
      return hms;
    } else if (hms.length < 6) {
      a = hms.split(':');
      return (hms = +a[0] * 60 + +a[1]);
    } else {
      a = hms.split(':');
      return (hms = +a[0] * 60 * 60 + +a[1] * 60 + +a[2]);
    }
  }

  function videoPlayerEvent(isPlaying) {
    // jwtplayer tends to send multiple 'play' actions. This check makes sure
    // we're not tracking repeated 'play' events for a single interaction.
    var eventName = isPlaying ? 'play' : 'pause';
    if (lastEvent === eventName) {
      return;
    }
    lastEvent = eventName;

    var metadata = videoMetadata(getById('video-player-source'));
    var properties = {
      article: metadata.id,
      deviceType: deviceType,
      action: eventName,
    };
    ahoy.track('Video Player Streaming', properties);
  }

  function initWebPlayer(seconds, metadata) {
    var waitingOnJWP = setInterval(function () {
      if (typeof jwplayer !== 'undefined') {
        clearInterval(waitingOnJWP);
        var playerInstance = jwplayer(`video-player-${metadata.id}`);
        playerInstance.setup({
          file: metadata.video_source_url,
          mediaid: metadata.video_code,
          image: metadata.video_thumbnail_url,
          playbackRateControls: true,
          tracks: [
            {
              file: metadata.video_closed_caption_track_url,
              label: 'English',
              kind: 'captions',
              default: false,
            },
          ],
        });
        if (seconds) {
          jwplayer().on('firstFrame', function () {
            jwplayer().seek(seconds);
          });
          jwplayer().on('play', function () {
            videoPlayerEvent(true);
          });
          jwplayer().on('pause', function () {
            videoPlayerEvent(false);
          });
        }
      }
    }, 2);
  }

  function videoMetadata(videoSource) {
    try {
      return JSON.parse(videoSource.dataset.meta);
    } catch (e) {
      console.log('Unable to load Podcast Episode metadata', e); // eslint-disable-line no-console
    }
  }

  function requestFocus() {
    var metadata = videoMetadata(videoSource);
    var playerElement = getById(`video-player-${metadata.id}`);

    getById('pause-butt').classList.add('active');
    getById('play-butt').classList.remove('active');

    Runtime.videoMessage({
      action: 'play',
      url: metadata.video_source_url,
      seconds: currentTime,
    });

    videoPlayerEvent(true);
  }

  function handleVideoMessages(event) {
    const message = JSON.parse(event.detail);
    if (message.namespace !== 'video') {
      return;
    }

    switch (message.action) {
      case 'play':
        getById('pause-butt').classList.add('active');
        getById('play-butt').classList.remove('active');
        videoPlayerEvent(true);
        break;
      case 'pause':
        getById('pause-butt').classList.remove('active');
        getById('play-butt').classList.add('active');
        videoPlayerEvent(false);
        break;
      case 'tick':
        currentTime = message.currentTime;
        break;
      default:
        console.log('Unrecognized message: ', message); // eslint-disable-line no-console
    }
  }

  function initializePlayer(videoSource) {
    var seconds = timeToSeconds(getParameterByName('t') || '0');
    var metadata = videoMetadata(videoSource);

    if (Runtime.isNativeIOS('video')) {
      deviceType = 'iOS';
    } else if (Runtime.isNativeAndroid('videoMessage')) {
      deviceType = 'Android';
    } else {
      // jwplayer is initialized and no further interaction is needed
      initWebPlayer(seconds, metadata);
      return;
    }

    Runtime.videoMessage = (msg) => {
      window.ForemMobile.injectNativeMessage('video', msg);
    };

    var playerElement = getById(`video-player-${metadata.id}`);
    playerElement.addEventListener('click', requestFocus);

    playerElement.classList.add('native');
    getById('play-butt').classList.add('active');

    document.addEventListener('ForemMobile', handleVideoMessages);

    currentTime = `${seconds}`;
  }

  // If an video player element is found initialize it
  var videoSource = getById('video-player-source');
  if (videoSource !== null) {
    initializePlayer(videoSource);
  }
}
