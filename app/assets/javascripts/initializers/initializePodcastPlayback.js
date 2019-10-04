'use strict';

/* eslint-disable no-param-reassign */
/* eslint-disable no-undef */

/**
 * This script hunts for podcast's "Record" for both the podcast_episde's
 * show page and an article page containing podcast liquid tag. It handles
 * playback and makes sure the record will spin when the podcast is currently
 * playing. The high level functions are the following
 *
 * - spinPodcastRecord();
 * - findAndApplyOnclickToRecords();
 */

function initializePodcastPlayback() {
  function getById(name) {
    return document.getElementById(name);
  }

  function getByClass(name) {
    return document.getElementsByClassName(name);
  }

  function audioExistAndIsPlaying() {
    return getById('audio') && !getById('audio').paused;
  }

  function recordExist() {
    return getById(`record-${window.activeEpisode}`);
  }

  function pausePodcastBar() {
    getById('barPlayPause').classList.remove('playing');
    getById('animated-bars').classList.remove('playing');
  }

  function changeStatusMessage(message) {
    if (getById(`status-message-${window.activeEpisode}`)) {
      getById(`status-message-${window.activeEpisode}`).innerHTML = message;
    } else if (
      message === 'loading' &&
      document.querySelector('.status-message')
    ) {
      document.querySelector('.status-message').innerHTML = message;
    }
  }

  function stopRotatingActivePodcastIfExist() {
    if (window.activeEpisode && getById(`record-${window.activeEpisode}`)) {
      getById(`record-${window.activeEpisode}`).classList.remove('playing');
      window.activeEpisode = undefined;
    }
  }

  function removeOnbeforeUnloadWarning() {
    window.onbeforeunload = () => {
      return null;
    };
  }

  function pauseAudioPlayback(audio) {
    audio.pause();
    stopRotatingActivePodcastIfExist();
    pausePodcastBar();
    removeOnbeforeUnloadWarning();
  }

  function playPause(audio) {
    changeStatusMessage('loading');
    window.activeEpisode = audio.getAttribute('data-episode');
    window.activePodcast = audio.getAttribute('data-podcast');
    if (audio.paused) {
      ga(
        'send',
        'event',
        'click',
        'play podcast',
        `${window.activePodcast} ${window.activeEpisode}`,
        null,
      );
      startAudioPlayback(audio);
    } else {
      ga(
        'send',
        'event',
        'click',
        'pause podcast',
        `${window.activePodcast} ${window.activeEpisode}`,
        null,
      );
      pauseAudioPlayback(audio);
    }
  }

  function muteUnmute(audio) {
    if (audio.muted) {
      audio.muted = false;
      getById('mutebutt').classList.add('hidden');
      getById('volumeindicator').classList.add('showing');
      getById('mutebutt').classList.remove('showing');
      getById('volumeindicator').classList.remove('hidden');
    } else {
      audio.muted = true;
      getById('mutebutt').classList.add('showing');
      getById('volumeindicator').classList.add('hidden');
      getById('mutebutt').classList.remove('hidden');
      getById('volumeindicator').classList.remove('showing');
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

  function updateProgress(e, audio) {
    var progress = getById('progress');
    var buffer = getById('buffer');
    var time = getById('time');
    var value = 0;
    var bufferValue = 0;
    if (audio.currentTime > 0) {
      value = Math.floor((100.0 / audio.duration) * audio.currentTime);
      bufferValue =
        (audio.buffered.end(audio.buffered.length - 1) / audio.duration) * 100;
    }
    progress.style.width = value + '%';
    buffer.style.width = bufferValue + '%';
    time.innerHTML =
      readableDuration(audio.currentTime) +
      ' / ' +
      readableDuration(audio.duration);
  }

  function goToTime(e, audio) {
    var progress = getById('progress');
    if (e.clientX > 128) {
      var percent = (e.clientX - 128) / (window.innerWidth - 133);
      var duration = audio.duration;
      audio.currentTime = duration * percent; // jumps to 29th secs
      time.innerHTML =
        readableDuration(audio.currentTime) +
        ' / ' +
        readableDuration(audio.duration);
      progress.style.width = percent * 100.0 + '%';
    }
  }

  function updateProgressListener(audio) {
    return e => {
      updateProgress(e, audio);
    };
  }

  function terminatePodcastBar(audio) {
    // eslint-disable-next-line no-restricted-globals
    event.stopPropagation();
    audio.removeEventListener('timeupdate', updateProgressListener, false);
    getById('audiocontent').innerHTML = '';
    stopRotatingActivePodcastIfExist();
    removeOnbeforeUnloadWarning();
  }

  function spinPodcastRecord(customMessage) {
    if (audioExistAndIsPlaying() && recordExist()) {
      getById(`record-${window.activeEpisode}`).classList.add('playing');
      changeStatusMessage(customMessage || 'playing');
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

  function changePlaybackRate(audio) {
    var el = getById('speed');
    var speed = parseFloat(el.getAttribute('data-speed'));
    if (speed === 2) {
      el.setAttribute('data-speed', 0.5);
      el.innerHTML = '0.5x';
      audio.playbackRate = 0.5;
    } else {
      el.setAttribute('data-speed', speed + 0.5);
      el.innerHTML = speed + 0.5 + 'x';
      audio.playbackRate = speed + 0.5;
    }
  }

  function applyOnclickToPodcastBar(audio) {
    getById('barPlayPause').onclick = () => {
      playPause(audio);
    };
    getById('mutebutt').onclick = () => {
      muteUnmute(audio);
    };
    getById('volbutt').onclick = () => {
      muteUnmute(audio);
    };
    getById('bufferwrapper').onclick = e => {
      goToTime(e, audio);
    };
    getById('volumeslider').value = audio.volume * 100;
    getById('volumeslider').onchange = e => {
      audio.volume = e.target.value / 100;
    };
    getById('speed').onclick = () => {
      changePlaybackRate(audio);
    };
    getById('closebutt').onclick = () => {
      terminatePodcastBar(audio);
    };
  }

  function podcastBarAlreadyExistAndPlayingTargetEpisode(episodeSlug) {
    return getById('audiocontent').innerHTML.indexOf(`${episodeSlug}`) !== -1;
  }

  function loadAndPlayNewPodcast(episodeSlug) {
    getById('audiocontent').innerHTML = getById(
      `hidden-audio-${episodeSlug}`,
    ).innerHTML;
    var audio = getById('audio');
    audio.addEventListener('timeupdate', updateProgressListener(audio), false);
    audio.load();
    playPause(audio);
    applyOnclickToPodcastBar(audio);
  }

  function findAndApplyOnclickToRecords() {
    var records = findRecords();
    Array.prototype.forEach.call(records, record => {
      var episodeSlug = record.getAttribute('data-episode');
      var podcastSlug = record.getAttribute('data-podcast');
      record.onclick = () => {
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
    });
  }

  function applyOnbeforeUnloadWarning() {
    var message =
      'You are currently playing a podcast. Are you sure you want to leave?';
    window.onclick = event => {
      if (
        event.target.tagName === 'A' &&
        !event.target.href.includes('https://dev.to') &&
        !event.ctrlKey &&
        !event.metaKey
      ) {
        event.preventDefault();
        if (window.confirm(message)) {
          window.location = event.target.href;
        }
      }
    };
    window.onbeforeunload = () => {
      return message;
    };
  }

  spinPodcastRecord();
  findAndApplyOnclickToRecords();
}
