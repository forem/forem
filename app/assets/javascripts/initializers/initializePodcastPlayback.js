'use strict'

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
    var currentState = currentAudioState();
    return getById('audio') && currentState.playing;
  }

  function recordExist() {
    return getById(`record-${window.activeEpisode}`);
  }

  function spinPodcastRecord(customMessage) {
    if (audioExistAndIsPlaying() && recordExist()) {
      getById(`record-${window.activeEpisode}`).classList.add('playing');
      changeStatusMessage(customMessage);
    }
  }

  function stopRotatingActivePodcastIfExist() {
    if (window.activeEpisode && getById(`record-${window.activeEpisode}`)) {
      getById(`record-${window.activeEpisode}`).classList.remove('playing');
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

  function applyOnclickToPodcastBar(audio) {
    var currentState = currentAudioState();
    getById('barPlayPause').onclick = function() {
      playPause(audio);
    };
    getById('mutebutt').onclick = function() {
      muteUnmute(audio);
    };
    getById('volbutt').onclick = function() {
      muteUnmute(audio);
    };
    getById('bufferwrapper').onclick = function(e) {
      goToTime(e, audio);
    };
    getById('volumeslider').value = currentState.volume * 100;
    getById('volumeslider').onchange = function(e) {
      updateVolume(e, audio);
    };
    getById('speed').onclick = function() {
      changePlaybackRate(audio);
    };
    getById('closebutt').onclick = function() {
      terminatePodcastBar(audio);
    };
  }

  function podcastBarAlreadyExistAndPlayingTargetEpisode(episodeSlug) {
    return getById('audiocontent').innerHTML.indexOf(`${episodeSlug}`) !== -1;
  }

  function updateProgressListener(audio) {
    return function(e) {
      var bufferValue = 0;
      if (audio.currentTime > 0) {
        var bufferEnd = audio.buffered.end(audio.buffered.length - 1);
        bufferValue = (bufferEnd / audio.duration) * 100;
      }
      updateProgress(audio.currentTime, audio.duration, bufferValue);
    };
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
    Array.prototype.forEach.call(records, function(record) {
      var episodeSlug = record.getAttribute('data-episode');
      var podcastSlug = record.getAttribute('data-podcast');
      record.onclick = function() {
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

  function changePlaybackRate(audio) {
    var currentState = currentAudioState();
    var el = getById('speed');
    var speed = parseFloat(el.getAttribute('data-speed'));
    if (speed == 2) {
      el.setAttribute('data-speed', 0.5);
      el.innerHTML = '0.5x';
      currentState.playbackRate = 0.5;
    } else {
      el.setAttribute('data-speed', speed + 0.5);
      el.innerHTML = speed + 0.5 + 'x';
      currentState.playbackRate = speed + 0.5;
    }
    saveMediaState(currentState);

    if (isNativeIOS()) {
      sendPodcastMessage('rate;' + currentState.playbackRate);
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
      document.querySelector('.status-message')
    ) {
      document.querySelector('.status-message').innerHTML = message;
    }
  }

  function startPodcastBar() {
    getById('barPlayPause').classList.add('playing');
    getById('progressBar').classList.add('playing');
    getById('animated-bars').classList.add('playing');
  }

  function playAudio(audio) {
    return new Promise(function (resolve, reject) {
      var currentState = currentAudioState();
      if (isNativeIOS()) {
        sendPodcastMessage('play;' + currentState.currentTime);
      } else {
        audio.currrentTime = currentState.currentTime;
        audio.play();
      }
      setPlaying(true);
      resolve();
    })
  }

  function loadAudio(audio) {
    if (isNativeIOS()) {
      sendPodcastMessage('load;' + audio.querySelector('source').src);
    } else {
      audio.load();
    }
  }

  function startAudioPlayback(audio) {
    playAudio(audio).then(
        function() {
          spinPodcastRecord();
          startPodcastBar();
        },
        function() {
          // Handle any pause() failures.
        },
      )
      .catch(function(error) {
        playAudio(audio);
        setTimeout(function() {
          spinPodcastRecord('initializing...');
          startPodcastBar();
        }, 5);
      });
  }

  function pausePodcastBar() {
    getById('barPlayPause').classList.remove('playing');
    getById('animated-bars').classList.remove('playing');
  }

  function pauseAudioPlayback(audio) {
    if (isNativeIOS()) {
      sendPodcastMessage('pause');
    } else {
      audio.pause();
    }
    setPlaying(false);
    stopRotatingActivePodcastIfExist();
    pausePodcastBar();
  }

  function isNativeIOS() {
    return navigator.userAgent === 'DEV-Native-ios';
  }

  function playPause(audio) {
    window.activeEpisode = audio.getAttribute('data-episode');
    window.activePodcast = audio.getAttribute('data-podcast');

    var currentState = currentAudioState();
    if (!currentState.playing) {
      ga(
        'send',
        'event',
        'click',
        'play podcast',
        `${window.activePodcast} ${window.activeEpisode}`,
        null,
      );
      changeStatusMessage('initializing...');
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
      changeStatusMessage(null);
    }
  }

  function muteUnmute(audio) {
    var currentState = currentAudioState();
    getById('mutebutt').classList.add(currentState.muted ? 'hidden' : 'showing');
    getById('volumeindicator').classList.add(currentState.muted ? 'showing' : 'hidden');
    getById('mutebutt').classList.remove(currentState.muted ? 'showing' : 'hidden');
    getById('volumeindicator').classList.remove(currentState.muted ? 'hidden' : 'showing');

    currentState.muted = !currentState.muted;
    if (isNativeIOS()) {
      sendPodcastMessage('muted;' + currentState.muted);
    } else {
      audio.muted = currentState.muted;
    }
    saveMediaState(currentState);
  }

  function updateVolume(e, audio) {
    var currentState = currentAudioState();
    currentState.volume = e.target.value / 100;
    if (isNativeIOS()) {
      sendPodcastMessage('volume;' + currentState.volume);
    } else {
      audio.volume = currentState.volume
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
      if(firstDecimal < 0.4) {
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
        readableDuration(currentTime) +
        ' / ' +
        readableDuration(duration);
    }
  }

  function goToTime(e, audio) {
    var currentState = currentAudioState();
    var progress = getById('progress');
    if (e.clientX > 128) {
      var percent = (e.clientX - 128) / (window.innerWidth - 133);
      var duration = currentState.duration;
      currentState.currentTime = duration * percent; // jumps to 29th secs

      if (isNativeIOS()) {
        sendPodcastMessage('seek;' + currentState.currentTime);
      } else {
        audio.currentTime = currentState.currentTime
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
    audio.removeEventListener('timeupdate', updateProgressListener(audio), false);
    getById('audiocontent').innerHTML = '';
    stopRotatingActivePodcastIfExist();
    if (isNativeIOS()) {
      sendPodcastMessage('terminate');
    }
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
  }

  function getMediaState() {
    var currentState = currentAudioState();
    document.getElementById('audiocontent').innerHTML = currentState.html;
    var audio = getById('audio');
    if (audio == undefined) {
      return;
    }
    if (!isNativeIOS()) {
      audio.currentTime = currentState.currentTime || 0;
    }
    loadAudio(audio);
    if (currentState.playing) {
      playAudio(audio).catch(function(error) {
        pausePodcastBar();
      });
    }
    setTimeout(function(){
      audio.addEventListener('timeupdate', updateProgressListener(audio), false);
      var mutationObserver = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          handlePodcastMessages(mutation);
        });
      });
      mutationObserver.observe(getById('audiocontent'), { attributes: true });
    },500)
    applyOnclickToPodcastBar(audio);
  }

  function handlePodcastMessages(mutation) {
    if (mutation.type == "attributes") {
      var message = getById('audiocontent').dataset.podcast;
      var action = message;
      var parameter = "";
      var separatorIndex = message.indexOf(';');
      if (separatorIndex > 0) {
        action = message.substring(0, separatorIndex);
        parameter = message.substring(separatorIndex + 1);
      }

      var currentState = currentAudioState();
      switch(action) {
        case 'time':
          currentState.currentTime = parameter;
          break;
        case 'duration':
          currentState.duration = parameter;
          break;
      }

      saveMediaState(currentState);
      updateProgress(currentState.currentTime, currentState.duration, 100);
    }
  }

  function currentAudioState() {
    try {
      var currentState = JSON.parse(localStorage.getItem('media_playback_state_v2'));
      if (!currentState || window.name !== currentState.windowName) {
        return newAudioState();
      }
      return currentState;
    } catch(e) {
      console.log(e)
      return newAudioState();
    }
  }

  function setPlaying(playing) {
    var currentState = currentAudioState();
    currentState.playing = playing;
    saveMediaState(currentState);
  }

  function newAudioState() {
    if (!window.name) {
      window.name = Math.random();
    }
    return {
      html: document.getElementById('audiocontent').innerHTML,
      currentTime: 0,
      playing: false,
      muted: false,
      volume: 1,
      duration: 1,
      updated: new Date().getTime(),
      windowName: window.name
    };
  }

  function sendPodcastMessage(message) {
    try {
      if (
        window &&
        window.webkit &&
        window.webkit.messageHandlers &&
        window.webkit.messageHandlers.podcast
      ) {
        window.webkit.messageHandlers.podcast.postMessage(message);
      }
    } catch (err) {
      console.log(err.message); // eslint-disable-line no-console
    }
  }

  spinPodcastRecord();
  findAndApplyOnclickToRecords();
  getMediaState();
  var audio = getById('audio');
  var audioContent = getById('audiocontent')
  if (audio && audioContent && audioContent.innerHTML.length < 25) { // audio not already loaded
    loadAudio(audio);
  }
}
