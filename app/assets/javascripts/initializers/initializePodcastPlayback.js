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
    return getById('audio') && !getById('audio').paused;
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
    getById('volumeslider').value = audio.volume * 100;
    getById('volumeslider').onchange = function(e) {
      audio.volume = e.target.value / 100;
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
      updateProgress(e, audio);
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
    var el = getById('speed');
    var speed = parseFloat(el.getAttribute('data-speed'));
    if (speed == 2) {
      el.setAttribute('data-speed', 0.5);
      el.innerHTML = '0.5x';
      audio.playbackRate = 0.5;
    } else {
      el.setAttribute('data-speed', speed + 0.5);
      el.innerHTML = speed + 0.5 + 'x';
      audio.playbackRate = speed + 0.5;
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

  function startAudioPlayback(audio) {
    audio
      .play()
      .then(
        function() {
          spinPodcastRecord();
          startPodcastBar();
        },
        function() {
          // Handle any pause() failures.
        },
      )
      .catch(function(error) {
        audio.play();
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
    audio.pause();
    stopRotatingActivePodcastIfExist();
    pausePodcastBar();
  }

  function playPause(audio) {
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
    setMediaState(audio)
  }

  function muteUnmute(audio) {
    getById('mutebutt').classList.add(audio.muted ? 'hidden' : 'showing');
    getById('volumeindicator').classList.add(audio.muted ? 'showing' : 'hidden');
    getById('mutebutt').classList.remove(audio.muted ? 'showing' : 'hidden');
    getById('volumeindicator').classList.remove(audio.muted ? 'hidden' : 'showing');
    audio.muted = !audio.muted;
  }

  function updateProgress(e, audio) {
    var progress = getById('progress');
    var buffer = getById('buffer');
    var time = getById('time');
    var value = 0;
    var bufferValue = 0;
    var currentTime = audio.currentTime;
    var firstDecimal = currentTime - Math.floor(currentTime);
    if (currentTime > 0) {
      value = Math.floor((100.0 / audio.duration) * audio.currentTime);
      bufferValue =
        (audio.buffered.end(audio.buffered.length - 1) / audio.duration) * 100;
      if(firstDecimal < 0.4) {
        // Rewrite to mediaState storage every few beats.
        setMediaState(audio)
      }
    }
    if (progress && time && currentTime > 0) {
      progress.style.width = value + '%';
      buffer.style.width = bufferValue + '%';
      time.innerHTML =
        readableDuration(audio.currentTime) +
        ' / ' +
        readableDuration(audio.duration);
    }
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

  function readableDuration(seconds) {
    var sec = Math.floor(seconds);
    var min = Math.floor(sec / 60);
    min = min >= 10 ? min : '0' + min;
    sec = Math.floor(sec % 60);
    sec = sec >= 10 ? sec : '0' + sec;
    return min + ':' + sec;
  }
  

  function terminatePodcastBar(audio) {
    audio.removeEventListener('timeupdate', updateProgressListener, false);
    getById('audiocontent').innerHTML = '';
    stopRotatingActivePodcastIfExist();
    setMediaState(audio);
  }

  function setMediaState(audio) {
    var date = new Date();
    var timeNumber = date.getTime();
    if (!window.name) {
      window.name = Math.random();
    }
    var newState = {
      html: document.getElementById('audiocontent').innerHTML,
      time: audio.currentTime,
      playing: !audio.paused,
      updated: timeNumber,
      windowName: window.name
    }
    localStorage.setItem('media_playback_state', JSON.stringify(newState));
  }

  function getMediaState() {
    try {
      var currentState = JSON.parse(localStorage.getItem('media_playback_state'));
      if (!currentState || getById('audiocontent').innerHTML.length > 50 || window.name !== currentState.windowName) {
        return;
      }
      document.getElementById('audiocontent').innerHTML = currentState.html;
      var audio = getById('audio');
      audio.currentTime = currentState.time;
      audio.load();
      if (currentState.playing) {
        audio.play().catch(function(error) {
          pausePodcastBar();
        });
      }
      setTimeout(function(){
        audio.addEventListener('timeupdate', updateProgressListener(audio), false);
      },500)
      applyOnclickToPodcastBar(audio);
    } catch(e) {
      console.log(e)
    }
  }

  spinPodcastRecord();
  findAndApplyOnclickToRecords();
  getMediaState();
  var audio = getById('audio');
  var audioContent = getById('audiocontent')
  if (audio && audioContent && audioContent.innerHTML.length < 25) { // audio not already loaded
    audio.load();
  }
}


