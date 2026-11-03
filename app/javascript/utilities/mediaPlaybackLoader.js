let pendingMediaPlaybackPromise = null;

/**
 * Checks whether the current page has podcast playback elements or a persisted
 * podcast playback session in localStorage.
 *
 * @param {object} [runtime]
 * @returns {boolean}
 */
export function shouldInitializePodcastPlayback(runtime) {
  if (typeof document === 'undefined') {
    return false;
  }

  if (
    document.getElementById('audio') ||
    document.getElementsByClassName('record-wrapper').length > 0 ||
    document.getElementsByClassName('podcastliquidtag__record').length > 0 ||
    Boolean(window.activeEpisode)
  ) {
    return true;
  }

  if (
    runtime?.isNativeIOS?.('podcast') ||
    runtime?.isNativeAndroid?.('podcastMessage')
  ) {
    return true;
  }

  try {
    const rawState = window.localStorage?.getItem('media_playback_state_v3');
    if (!rawState) {
      return false;
    }
    const parsedState = JSON.parse(rawState);
    return Boolean(
      parsedState &&
        (parsedState.playing || parsedState.playbackName || parsedState.html),
    );
  } catch {
    return false;
  }
}

/**
 * Ensures the `mediaPlayback` pack (`podcastPlayback` + `videoPlayback`) is loaded.
 *
 * @returns {Promise<{ initializePodcastPlayback: Function, initializeVideoPlayback: Function }>}
 */
export function loadMediaPlaybackBundle() {
  if (
    typeof window !== 'undefined' &&
    typeof window.Forem?.initializePodcastPlayback === 'function' &&
    typeof window.Forem?.initializeVideoPlayback === 'function'
  ) {
    return Promise.resolve({
      initializePodcastPlayback: window.Forem.initializePodcastPlayback,
      initializeVideoPlayback: window.Forem.initializeVideoPlayback,
    });
  }

  if (pendingMediaPlaybackPromise) {
    return pendingMediaPlaybackPromise;
  }

  const metaTag = document.querySelector('meta[name="media-playback-script"]');
  const scriptSrc = metaTag?.content || '/assets/mediaPlayback.js';

  pendingMediaPlaybackPromise = new Promise((resolve, reject) => {
    const existingScript = document.querySelector(
      `script[src="${scriptSrc}"], script[data-media-playback-bundle="true"]`,
    );
    const script = existingScript || document.createElement('script');

    const cleanupFailure = (err) => {
      pendingMediaPlaybackPromise = null;
      if (!existingScript) {
        script.remove();
      }
      reject(err);
    };

    script.addEventListener(
      'load',
      () => {
        if (typeof window.Forem?.initializePodcastPlayback === 'function') {
          resolve({
            initializePodcastPlayback: window.Forem.initializePodcastPlayback,
            initializeVideoPlayback: window.Forem.initializeVideoPlayback,
          });
        } else {
          cleanupFailure(
            new Error(
              'mediaPlayback bundle loaded without registering initializePodcastPlayback',
            ),
          );
        }
      },
      { once: true },
    );

    script.addEventListener(
      'error',
      () => {
        cleanupFailure(new Error(`Failed to load ${scriptSrc}`));
      },
      { once: true },
    );

    if (!existingScript) {
      script.src = scriptSrc;
      script.defer = true;
      script.dataset.mediaPlaybackBundle = 'true';
      document.head.appendChild(script);
    }
  });

  return pendingMediaPlaybackPromise;
}

export function resetMediaPlaybackLoaderForTests() {
  pendingMediaPlaybackPromise = null;
}
