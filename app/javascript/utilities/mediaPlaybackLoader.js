import { createAssetBundleLoader } from './loadAssetBundle';

const mediaPlaybackBundleLoader = createAssetBundleLoader({
  metaName: 'media-playback-script',
  fallbackSrc: '/assets/mediaPlayback.js',
  dataAttribute: 'mediaPlaybackBundle',
  getReadyValue: () =>
    typeof window.Forem?.initializePodcastPlayback === 'function'
      ? {
          initializePodcastPlayback: window.Forem.initializePodcastPlayback,
          initializeVideoPlayback: window.Forem.initializeVideoPlayback,
        }
      : null,
  errorMessage:
    'mediaPlayback bundle loaded without registering initializePodcastPlayback',
});

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
  return mediaPlaybackBundleLoader.load();
}

export function resetMediaPlaybackLoaderForTests() {
  mediaPlaybackBundleLoader.reset();
}
