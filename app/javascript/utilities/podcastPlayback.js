/**
 * This script hunts for podcast's "Record" for both the podcast_episode's
 * show page and an article page containing podcast liquid tag. It handles
 * playback and makes sure the record will spin when the podcast is currently
 * playing.
 *
 * The media is initialized (once) and the "state" is stored using localStorage.
 * When playback is the website's responsability it's run using the `audio` HTML
 * element. The iOS/Android apps uses a bridging strategy that sends messages
 * using webkit messageHandlers and receives incoming messages through the
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

/* eslint no-use-before-define: 0 */
/* eslint no-param-reassign: 0 */

import ahoy from 'ahoy.js';

export function initializePodcastPlayback() {
  let deviceType = 'web';

  function getById(name) {
    return document.getElementById(name);
  }

  function getByClass(name) {
    return document.getElementsByClassName(name);
  }

  function newAudioState() {
    const audio = getById('audio');
    window.activeEpisode = audio?.dataset?.episode;
    window.activePodcast = audio?.dataset?.podcast;

    return {
      html: getById('audiocontent').innerHTML,
      currentTime: 0,
      playing: false,
      muted: false,
      volume: 1,
      duration: 1,
      updated: new Date().getTime(),
      playbackName: audio?.dataset?.episode,
    };
  }

  function currentAudioState() {
    try {
      const currentState = JSON.parse(
        localStorage.getItem('media_playback_state_v3'),
      );
      if (!currentState) {
        return newAudioState();
      }
      return currentState;
    } catch (e) {
      return newAudioState();
    }
  }

  function audioExistAndIsPlaying() {
    return getById('audio') && currentAudioState().playing;
  }

  function recordExist() {
    return getById(`record-${window.activeEpisode}`);
  }

  function spinPodcastRecord(customMessage) {
    if (audioExistAndIsPlaying() && recordExist()) {
      const podcastPlaybackButton = getById(`record-${window.activeEpisode}`);
      podcastPlaybackButton.classList.add('playing');
      podcastPlaybackButton.setAttribute('aria-pressed', 'true');
      changeStatusMessage(customMessage);
    } else {
      stopRotatingActivePodcastIfExist();
    }
  }

  function stopRotatingActivePodcastIfExist() {
    if (window.activeEpisode && getById(`record-${window.activeEpisode}`)) {
      const podcastPlaybackButton = getById(`record-${window.activeEpisode}`);
      podcastPlaybackButton.classList.remove('playing');
      podcastPlaybackButton.setAttribute('aria-pressed', 'false');
      window.activeEpisode = undefined;
    }
  }

  function findRecords() {
    const podcastPageRecords = getByClass('record-wrapper');
    const podcastLiquidTagrecords = getByClass('podcastliquidtag__record');
    if (podcastPageRecords.length > 0) {
      return podcastPageRecords;
    }
    return podcastLiquidTagrecords;
  }

  function saveMediaState(state) {
    const currentState = state || currentAudioState();
    const newState = newAudioState();
    newState.currentTime = currentState.currentTime;
    newState.playing = currentState.playing;
    newState.muted = currentState.muted;
    newState.volume = currentState.volume;
    newState.duration = currentState.duration;
    localStorage.setItem('media_playback_state_v3', JSON.stringify(newState));
    return newState;
  }

  function applyOnclickToPodcastBar(audio) {
    const currentState = currentAudioState();
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
    return () => {
      let bufferValue = 0;
      if (audio.currentTime > 0) {
        const bufferEnd = audio.buffered.end(audio.buffered.length - 1);
        bufferValue = (bufferEnd / audio.duration) * 100;
      }
      updateProgress(audio.currentTime, audio.duration, bufferValue);
    };
  }

  function loadAudio(audio) {
    if (window.Forem.Runtime.podcastMessage) {
      window.Forem.Runtime.podcastMessage({
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
    const audio = getById('audio');
    audio.addEventListener('timeupdate', updateProgressListener(audio), false);
    loadAudio(audio);
    playPause(audio);
    applyOnclickToPodcastBar(audio);
  }

  function findAndApplyOnclickToRecords() {
    const records = findRecords();
    Array.prototype.forEach.call(records, (record) => {
      const episodeSlug = record.getAttribute('data-episode');
      const togglePodcastState = () => {
        if (podcastBarAlreadyExistAndPlayingTargetEpisode(episodeSlug)) {
          const audio = getById('audio');
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
    const currentState = currentAudioState();
    const el = getById('speed');
    const speed = parseFloat(el.getAttribute('data-speed'));
    if (speed === 2) {
      el.setAttribute('data-speed', 0.5);
      el.innerHTML = '0.5x';
      currentState.playbackRate = 0.5;
    } else {
      el.setAttribute('data-speed', speed + 0.5);
      el.innerHTML = `${speed + 0.5}x`;
      currentState.playbackRate = speed + 0.5;
    }
    saveMediaState(currentState);

    if (window.Forem.Runtime.podcastMessage) {
      window.Forem.Runtime.podcastMessage({
        action: 'rate',
        rate: currentState.playbackRate.toString(),
      });
    } else {
      audio.playbackRate = currentState.playbackRate;
    }
  }

  function changeStatusMessage(message) {
    const currentState = currentAudioState();
    const statusBox = getById(`status-message-${currentState.playbackName}`);
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
    return new Promise((resolve, reject) => {
      const currentState = currentAudioState();
      if (window.Forem.Runtime.podcastMessage) {
        window.Forem.Runtime.podcastMessage({
          action: 'play',
          url: audio.getElementsByTagName('source')[0].src,
          seconds: currentState.currentTime.toString(),
        });
        setPlaying(true);
        resolve();
      } else {
        audio.currentTime = currentState.currentTime;
        audio
          .play()
          .then(() => {
            setPlaying(true);
            resolve();
          })
          .catch(() => {
            setPlaying(false);
            reject();
          });
      }
    });
  }

  function fetchMetadataString() {
    let episodeContainer = getByClass('podcast-episode-container')[0];
    if (episodeContainer === undefined) {
      episodeContainer = getByClass('podcastliquidtag')[0];
    }
    return episodeContainer.dataset.meta;
  }

  function sendMetadataMessage() {
    if (window.Forem.Runtime.podcastMessage) {
      try {
        const metadata = JSON.parse(fetchMetadataString());
        window.Forem.Runtime.podcastMessage({
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
      .then(() => {
        spinPodcastRecord();
        startPodcastBar();
      })
      .catch(() => {
        playAudio(audio);
        setTimeout(() => {
          spinPodcastRecord('initializing...');
          startPodcastBar();
        }, 5);
      });
  }

  function pauseAudioPlayback(audio) {
    if (window.Forem.Runtime.podcastMessage) {
      window.Forem.Runtime.podcastMessage({ action: 'pause' });
    } else {
      audio.pause();
    }
    setPlaying(false);
    stopRotatingActivePodcastIfExist();
    pausePodcastBar();
  }

  function ahoyMessage(action) {
    const properties = {
      action,
      episode: window.activeEpisode,
      podcast: window.activePodcast,
      deviceType,
    };
    ahoy.track('Podcast Player Streaming', properties);
  }

  function playPause(audio) {
    let currentState = currentAudioState();
    if (currentState.playbackName != getById('audio').dataset.episode) {
      currentState = newAudioState();
      saveMediaState(currentState);
    }

    if (!currentState.playing) {
      ahoyMessage('play');
      changeStatusMessage(null);
      startAudioPlayback(audio);
    } else {
      ahoyMessage('pause');
      pauseAudioPlayback(audio);
      changeStatusMessage(null);
    }
    spinPodcastRecord();
  }

  function muteUnmute(audio) {
    const currentState = currentAudioState();
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
    if (window.Forem.Runtime.podcastMessage) {
      window.Forem.Runtime.podcastMessage({
        action: 'muted',
        muted: currentState.muted.toString(),
      });
    } else {
      audio.muted = currentState.muted;
    }
    saveMediaState(currentState);
  }

  function updateVolume(e, audio) {
    const currentState = currentAudioState();
    currentState.volume = e.target.value / 100;
    if (window.Forem.Runtime.podcastMessage) {
      window.Forem.Runtime.podcastMessage({
        action: 'volume',
        volume: currentState.volume,
      });
    } else {
      audio.volume = currentState.volume;
    }
    saveMediaState(currentState);
  }

  function updateProgress(currentTime, duration, bufferValue) {
    const progress = getById('progress');
    const buffer = getById('buffer');
    const time = getById('time');
    let value = 0;
    const firstDecimal = currentTime - Math.floor(currentTime);
    if (currentTime > 0) {
      value = Math.floor((100.0 / duration) * currentTime);
      if (firstDecimal < 0.4) {
        // Rewrite to mediaState storage every few beats.
        const currentState = currentAudioState();
        currentState.duration = duration;
        currentState.currentTime = currentTime;
        saveMediaState(currentState);
      }
    }
    if (progress && time && currentTime > 0) {
      progress.style.width = `${value}%`;
      buffer.style.width = `${bufferValue}%`;
      time.innerHTML = `${readableDuration(currentTime)} / ${readableDuration(
        duration,
      )}`;
    }
  }

  function goToTime(e, audio) {
    const currentState = currentAudioState();
    const progress = getById('progress');
    const time = getById('time');
    if (e.clientX > 128) {
      const percent = (e.clientX - 128) / (window.innerWidth - 133);
      currentState.currentTime = currentState.duration * percent; // jumps to 29th secs

      if (window.Forem.Runtime.podcastMessage) {
        window.Forem.Runtime.podcastMessage({
          action: 'seek',
          seconds: currentState.currentTime.toString(),
        });
      } else {
        audio.currentTime = currentState.currentTime;
      }

      const currentTime = readableDuration(currentState.currentTime);
      const duration = readableDuration(currentState.duration);
      time.innerHTML = `${currentTime} / ${duration}`;
      progress.style.width = `${percent * 100.0}%`;
    }
  }

  function readableDuration(seconds) {
    let sec = Math.floor(seconds);
    let min = Math.floor(sec / 60);
    min = min >= 10 ? min : `0${min}`;
    sec = Math.floor(sec % 60);
    sec = sec >= 10 ? sec : `0${sec}`;
    return `${min}:${sec}`;
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
    if (window.Forem.Runtime.podcastMessage) {
      window.Forem.Runtime.podcastMessage({ action: 'terminate' });
    }
  }

  function handlePodcastMessages(event) {
    const message = JSON.parse(event.detail);
    if (message.namespace !== 'podcast') {
      return;
    }

    const currentState = currentAudioState();
    switch (message.action) {
      case 'init':
        getById('time').innerHTML = 'initializing...';
        currentState.currentTime = 0;
        break;
      case 'play':
        ahoyMessage('play');
        spinPodcastRecord();
        startPodcastBar();
        break;
      case 'pause':
        ahoyMessage('pause');
        setPlaying(false);
        stopRotatingActivePodcastIfExist();
        pausePodcastBar();
        break;
      case 'tick':
        currentState.currentTime = message.currentTime;
        currentState.duration = message.duration;
        updateProgress(currentState.currentTime, currentState.duration, 100);
        break;
      default:
        console.log('Unrecognized message: ', message); // eslint-disable-line no-console
    }

    saveMediaState(currentState);
  }

  // When window.Forem.Runtime.podcastMessage is undefined we need to execute web logic
  function initRuntime() {
    if (window.Forem.Runtime.isNativeIOS('podcast')) {
      deviceType = 'iOS';
    } else if (window.Forem.Runtime.isNativeAndroid('podcastMessage')) {
      deviceType = 'Android';
    }

    if (deviceType !== 'web') {
      window.Forem.Runtime.podcastMessage = (msg) => {
        window.ForemMobile.injectNativeMessage('podcast', msg);
      };
    }
  }

  function initializeMedia() {
    const currentState = currentAudioState();
    document.getElementById('audiocontent').innerHTML = currentState.html;
    const audio = getById('audio');
    if (audio === undefined || audio === null) {
      window.Forem.audioInitialized = false;
      return;
    }
    if (window.Forem.Runtime.podcastMessage) {
      audio.currentTime = currentState.currentTime || 0;
    }
    loadAudio(audio);
    if (currentState.playing) {
      playAudio(audio).catch(() => {
        pausePodcastBar();
      });
    }
    setTimeout(() => {
      audio.addEventListener(
        'timeupdate',
        updateProgressListener(audio),
        false,
      );
      document.addEventListener('ForemMobile', handlePodcastMessages);
    }, 500);
    applyOnclickToPodcastBar(audio);
  }

  function setPlaying(playing) {
    const currentState = currentAudioState();
    currentState.playing = playing;
    saveMediaState(currentState);
  }

  initRuntime();
  spinPodcastRecord();
  findAndApplyOnclickToRecords();
  if (!window.Forem.audioInitialized) {
    window.Forem.audioInitialized = true;
    initializeMedia();
  }
  const audio = getById('audio');
  const audioContent = getById('audiocontent');
  if (audio && audioContent && audioContent.innerHTML.length < 25) {
    // audio not already loaded
    loadAudio(audio);
  }
}
