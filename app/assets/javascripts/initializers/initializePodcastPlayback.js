/**
 * This script hunts for podcast's "Record" for both the podcast_episde's
 * show page and an article page containing podcast liquid tag. It handles
 * playback and makes sure the record will spin when the podcast is currently
 * playing.
 *
 * The media is initialized (once) and the "state" is stored using localStorage.
 * When playback is the website's responsability it's run using the `audio` HTML
 * element. The iOS app uses a bridging strategy that sends messages using
 * webkit messageHandlers and receives incoming messages through the
 * `contentaudio` element, which allows for native audio playback.
 *
 * The high level functions are the following:
 * - spinPodcastRecord()
 * - findAndApplyOnclickToRecords()
 * - initializeMedia()
 * - currentAudioState()
 * - saveMediaState()
 *
 * The following are useful eslint disables for this file in particular. Because
 * of the way it's wrapped around its own function (own context) we don't have
 * the problem of using a method before it's defined:
 */

/* global ahoy, Runtime */
/* eslint no-use-before-define: 0 */
/* eslint no-param-reassign: 0 */

var audioInitialized = false;

function initializePodcastPlayback() {
  var deviceType = 'web';

  function getById(name) {
    return document.getElementById(name);
  }

  function getByClass(name) {
    return document.getElementsByClassName(name);
  }

  function newAudioState() {
    if (!window.name) {
      window.name = Math.random();
    }
    return {
      html: getById('audiocontent').innerHTML,
      currentTime: 0,
      playing: false,
      muted: false,
      volume: 1,
      duration: 1,
      updated: new Date().getTime(),
      windowName: window.name,
    };
  }

  function currentAudioState() {
    try {
      var currentState = JSON.parse(
        localStorage.getItem('media_playback_state_v2'),
      );
      if (!currentState || window.name !== currentState.windowName) {
        return newAudioState();
      }
      return currentState;
    } catch (e) {
      console.log(e); // eslint-disable-line no-console
      return newAudioState();
    }
  }

  function audioExistAndIsPlaying() {
    var audio = getById('audio');
    var currentState = currentAudioState();
    return audio && currentState.playing;
  }

  function recordExist() {
    return getById(`record-${window.activeEpisode}`);
  }

  function spinPodcastRecord(customMessage) {
    if (audioExistAndIsPlaying() && recordExist()) {
      var podcastPlaybackButton = getById(`record-${window.activeEpisode}`);
      podcastPlaybackButton.classList.add('playing');
      podcastPlaybackButton.setAttribute('aria-pressed', 'true');
      changeStatusMessage(customMessage);
    }
  }

  function stopRotatingActivePodcastIfExist() {
    if (window.activeEpisode && getById(`record-${window.activeEpisode}`)) {
      var podcastPlaybackButton = getById(`record-${window.activeEpisode}`);
      podcastPlaybackButton.classList.remove('playing');
      podcastPlaybackButton.setAttribute('aria-pressed', 'false');
      window.activeEpisode = undefined;
    }
  }

  function findRecords() {
    var podcastPageRecords = getByClass('record-wrapper');
    var podcastLiquidTagrecords = getByClass('podcastliquidtag__record');
    if (podcastPageRecords.length > 0) {
      return podcastPageRecords;
    }
    return podcastLiquidTagrecords;
  }

  function saveMediaState(state) {
    var currentState = state || currentAudioState();
    var newState = newAudioState();
    newState.currentTime = currentState.currentTime;
    newState.playing = currentState.playing;
    newState.muted = currentState.muted;
    newState.volume = currentState.volume;
    newState.duration = currentState.duration;
    localStorage.setItem('media_playback_state_v2', JSON.stringify(newState));
    return newState;
  }

  function applyOnclickToPodcastBar(audio) {
    var currentState = currentAudioState();
    getById('barPlayPause').onclick = function () {
      playPause(audio);
    };
    getById('mutebutt').onclick = function () {
      muteUnmute(audio);
    };
    getById('volbutt').onclick = function () {
      muteUnmute(audio);
    };
    getById('bufferwrapper').onclick = function (e) {
      goToTime(e, audio);
    };
    getById('volumeslider').value = currentState.volume * 100;
    getById('volumeslider').onchange = function (e) {
      updateVolume(e, audio);
    };
    getById('speed').onclick = function () {
      changePlaybackRate(audio);
    };
    getById('closebutt').onclick = function () {
      terminatePodcastBar(audio);
    };
  }

  function podcastBarAlreadyExistAndPlayingTargetEpisode(episodeSlug) {
    return getById('audiocontent').innerHTML.indexOf(`${episodeSlug}`) !== -1;
  }

  function updateProgressListener(audio) {
    return function (e) {
      var bufferValue = 0;
      if (audio.currentTime > 0) {
        var bufferEnd = audio.buffered.end(audio.buffered.length - 1);
        bufferValue = (bufferEnd / audio.duration) * 100;
      }
      updateProgress(audio.currentTime, audio.duration, bufferValue);
    };
  }

  function loadAudio(audio) {
    if (Runtime.podcastMessage) {
      Runtime.podcastMessage({
        action: 'load',
        url: audio.getElementsByTagName('source')[0].src,
      });
    } else {
      audio.load();
    }
  }

  function loadAndPlayNewPodcast(episodeSlug) {
    getById('audiocontent').innerHTML = getById(
      `hidden-audio-${episodeSlug}`,
    ).innerHTML;
    var audio = getById('audio');
    audio.addEventListener('timeupdate', updateProgressListener(audio), false);
    loadAudio(audio);
    playPause(audio);
    applyOnclickToPodcastBar(audio);
  }

  function findAndApplyOnclickToRecords() {
    var records = findRecords();
    Array.prototype.forEach.call(records, function (record) {
      var episodeSlug = record.getAttribute('data-episode');
      var podcastSlug = record.getAttribute('data-podcast');

      var togglePodcastState = function (e) {
        if (podcastBarAlreadyExistAndPlayingTargetEpisode(episodeSlug)) {
          var audio = getById('audio');
          if (audio) {
            playPause(audio);
          }
        } else {
          stopRotatingActivePodcastIfExist();
          loadAndPlayNewPodcast(episodeSlug);
        }
      };
      record.addEventListener('click', togglePodcastState);
    });
  }

  function changePlaybackRate(audio) {
    var currentState = currentAudioState();
    var el = getById('speed');
    var speed = parseFloat(el.getAttribute('data-speed'));
    if (speed === 2) {
      el.setAttribute('data-speed', 0.5);
      el.innerHTML = '0.5x';
      currentState.playbackRate = 0.5;
    } else {
      el.setAttribute('data-speed', speed + 0.5);
      el.innerHTML = speed + 0.5 + 'x';
      currentState.playbackRate = speed + 0.5;
    }
    saveMediaState(currentState);

    if (Runtime.podcastMessage) {
      Runtime.podcastMessage({
        action: 'rate',
        rate: currentState.playbackRate.toString(),
      });
    } else {
      audio.playbackRate = currentState.playbackRate;
    }
  }

  function changeStatusMessage(message) {
    var statusBox = getById(`status-message-${window.activeEpisode}`);
    if (statusBox) {
      if (message) {
        statusBox.classList.add('showing');
        statusBox.innerHTML = message;
      } else {
        statusBox.classList.remove('showing');
      }
    } else if (
      message === 'initializing...' &&
      getByClass('status-message')[0]
    ) {
      getByClass('status-message')[0].innerHTML = message;
    }
  }

  function startPodcastBar() {
    getById('barPlayPause').classList.add('playing');
    getById('progressBar').classList.add('playing');
    getById('animated-bars').classList.add('playing');
  }

  function pausePodcastBar() {
    getById('barPlayPause').classList.remove('playing');
    getById('animated-bars').classList.remove('playing');
  }

  function playAudio(audio) {
    return new Promise(function (resolve, reject) {
      var currentState = currentAudioState();
      if (Runtime.podcastMessage) {
        Runtime.podcastMessage({
          action: 'play',
          url: audio.getElementsByTagName('source')[0].src,
          seconds: currentState.currentTime.toString(),
        });
        setPlaying(true);
        resolve();
      } else {
        audio.currrentTime = currentState.currentTime;
        audio
          .play()
          .then(function () {
            setPlaying(true);
            resolve();
          })
          .catch(function (error) {
            console.log(error); // eslint-disable-line no-console
            setPlaying(false);
            reject();
          });
      }
    });
  }

  function fetchMetadataString() {
    var episodeContainer = getByClass('podcast-episode-container')[0];
    if (episodeContainer === undefined) {
      episodeContainer = getByClass('podcastliquidtag')[0];
    }
    return episodeContainer.dataset.meta;
  }

  function sendMetadataMessage() {
    if (Runtime.podcastMessage) {
      try {
        var metadata = JSON.parse(fetchMetadataString());
        Runtime.podcastMessage({
          action: 'metadata',
          episodeName: metadata.episodeName,
          podcastName: metadata.podcastName,
          podcastImageUrl: metadata.podcastImageUrl,
        });
      } catch (e) {
        console.log('Unable to load Podcast Episode metadata', e); // eslint-disable-line no-console
      }
    }
  }

  function startAudioPlayback(audio) {
    sendMetadataMessage();

    playAudio(audio)
      .then(function () {
        spinPodcastRecord();
        startPodcastBar();
      })
      .catch(function (error) {
        playAudio(audio);
        setTimeout(function () {
          spinPodcastRecord('initializing...');
          startPodcastBar();
        }, 5);
      });
  }

  function pauseAudioPlayback(audio) {
    if (Runtime.podcastMessage) {
      Runtime.podcastMessage({ action: 'pause' });
    } else {
      audio.pause();
    }
    setPlaying(false);
    stopRotatingActivePodcastIfExist();
    pausePodcastBar();
  }

  function ahoyMessage(action) {
    window.activeEpisode = audio.getAttribute('data-episode');
    window.activePodcast = audio.getAttribute('data-podcast');

    var properties = {
      action: action,
      episode: window.activeEpisode,
      podcast: window.activePodcast,
      deviceType: deviceType,
    };
    ahoy.track('Podcast Player Streaming', properties);
  }

  function playPause(audio) {
    var currentState = currentAudioState();
    if (!currentState.playing) {
      ahoyMessage('play');
      changeStatusMessage('initializing...');
      startAudioPlayback(audio);
    } else {
      ahoyMessage('pause');
      pauseAudioPlayback(audio);
      changeStatusMessage(null);
    }
  }

  function muteUnmute(audio) {
    var currentState = currentAudioState();
    getById('mutebutt').classList.add(
      currentState.muted ? 'hidden' : 'showing',
    );
    getById('volumeindicator').classList.add(
      currentState.muted ? 'showing' : 'hidden',
    );
    getById('mutebutt').classList.remove(
      currentState.muted ? 'showing' : 'hidden',
    );
    getById('volumeindicator').classList.remove(
      currentState.muted ? 'hidden' : 'showing',
    );

    currentState.muted = !currentState.muted;
    if (Runtime.podcastMessage) {
      Runtime.podcastMessage({
        action: 'muted',
        muted: currentState.muted.toString(),
      });
    } else {
      audio.muted = currentState.muted;
    }
    saveMediaState(currentState);
  }

  function updateVolume(e, audio) {
    var currentState = currentAudioState();
    currentState.volume = e.target.value / 100;
    if (Runtime.podcastMessage) {
      Runtime.podcastMessage({ action: 'volume', volume: currentState.volume });
    } else {
      audio.volume = currentState.volume;
    }
    saveMediaState(currentState);
  }

  function updateProgress(currentTime, duration, bufferValue) {
    var progress = getById('progress');
    var buffer = getById('buffer');
    var time = getById('time');
    var value = 0;
    var firstDecimal = currentTime - Math.floor(currentTime);
    if (currentTime > 0) {
      value = Math.floor((100.0 / duration) * currentTime);
      if (firstDecimal < 0.4) {
        // Rewrite to mediaState storage every few beats.
        var currentState = currentAudioState();
        currentState.duration = duration;
        currentState.currentTime = currentTime;
        saveMediaState(currentState);
      }
    }
    if (progress && time && currentTime > 0) {
      progress.style.width = value + '%';
      buffer.style.width = bufferValue + '%';
      time.innerHTML =
        readableDuration(currentTime) + ' / ' + readableDuration(duration);
    }
  }

  function goToTime(e, audio) {
    var currentState = currentAudioState();
    var progress = getById('progress');
    var time = getById('time');
    if (e.clientX > 128) {
      var percent = (e.clientX - 128) / (window.innerWidth - 133);
      var duration = currentState.duration;
      currentState.currentTime = duration * percent; // jumps to 29th secs

      if (Runtime.podcastMessage) {
        Runtime.podcastMessage({
          action: 'seek',
          seconds: currentState.currentTime.toString(),
        });
      } else {
        audio.currentTime = currentState.currentTime;
      }

      time.innerHTML =
        readableDuration(currentState.currentTime) +
        ' / ' +
        readableDuration(currentState.duration);
      progress.style.width = percent * 100.0 + '%';
    }
  }

  function readableDuration(seconds) {
    var sec = Math.floor(seconds);
    var min = Math.floor(sec / 60);
    min = min >= 10 ? min : '0' + min;
    sec = Math.floor(sec % 60);
    sec = sec >= 10 ? sec : '0' + sec;
    return min + ':' + sec;
  }

  function terminatePodcastBar(audio) {
    audio.removeEventListener(
      'timeupdate',
      updateProgressListener(audio),
      false,
    );
    getById('audiocontent').innerHTML = '';
    stopRotatingActivePodcastIfExist();
    saveMediaState(newAudioState());
    if (Runtime.podcastMessage) {
      Runtime.podcastMessage({ action: 'terminate' });
    }
  }

  function handlePodcastMessages(mutation) {
    if (mutation.type !== 'attributes') {
      return;
    }

    var message = {};
    try {
      var messageData = getById('audiocontent').dataset.podcast;
      message = JSON.parse(messageData);
    } catch (e) {
      console.log(e); // eslint-disable-line no-console
      return;
    }

    var currentState = currentAudioState();
    switch (message.action) {
      case 'init':
        getById('time').innerHTML = 'initializing...';
        currentState.currentTime = 0;
        break;
      case 'tick':
        currentState.currentTime = message.currentTime;
        currentState.duration = message.duration;
        updateProgress(currentState.currentTime, currentState.duration, 100);
        break;
      default:
        console.log('Unrecognized podcast message: ', message); // eslint-disable-line no-console
    }

    saveMediaState(currentState);
  }

  function addMutationObserver() {
    var mutationObserver = new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        handlePodcastMessages(mutation);
      });
    });
    mutationObserver.observe(getById('audiocontent'), { attributes: true });
  }

  // When Runtime.podcastMessage is undefined we need to execute web logic
  function initRuntime() {
    if (Runtime.isNativeIOS('podcast')) {
      deviceType = 'iOS';
      Runtime.podcastMessage = function (message) {
        try {
          window.webkit.messageHandlers.podcast.postMessage(message);
        } catch (err) {
          console.log(err.message); // eslint-disable-line no-console
        }
      };
    } else if (Runtime.isNativeAndroid('podcastMessage')) {
      deviceType = 'Android';
      Runtime.podcastMessage = function (message) {
        try {
          AndroidBridge.podcastMessage(JSON.stringify(message));
        } catch (err) {
          console.log(err.message); // eslint-disable-line no-console
        }
      };
    }
  }

  function initializeMedia() {
    var currentState = currentAudioState();
    document.getElementById('audiocontent').innerHTML = currentState.html;
    var audio = getById('audio');
    if (audio === undefined || audio === null) {
      audioInitialized = false;
      return;
    }
    if (Runtime.podcastMessage) {
      audio.currentTime = currentState.currentTime || 0;
    }
    loadAudio(audio);
    if (currentState.playing) {
      playAudio(audio).catch(function (error) {
        pausePodcastBar();
      });
    }
    setTimeout(function () {
      audio.addEventListener(
        'timeupdate',
        updateProgressListener(audio),
        false,
      );
      addMutationObserver();
    }, 500);
    applyOnclickToPodcastBar(audio);
  }

  function setPlaying(playing) {
    var currentState = currentAudioState();
    currentState.playing = playing;
    saveMediaState(currentState);
  }

  initRuntime();
  spinPodcastRecord();
  findAndApplyOnclickToRecords();
  if (!audioInitialized) {
    audioInitialized = true;
    initializeMedia();
  }
  var audio = getById('audio');
  var audioContent = getById('audiocontent');
  if (audio && audioContent && audioContent.innerHTML.length < 25) {
    // audio not already loaded
    loadAudio(audio);
  }
}
