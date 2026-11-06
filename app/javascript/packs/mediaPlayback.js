import { initializePodcastPlayback } from '../utilities/podcastPlayback';
import { initializeVideoPlayback } from '../utilities/videoPlayback';

if (typeof window !== 'undefined') {
  window.Forem = window.Forem || {};
  window.Forem.initializePodcastPlayback = initializePodcastPlayback;
  window.Forem.initializeVideoPlayback = initializeVideoPlayback;
  window.initializePodcastPlayback = initializePodcastPlayback;
}

export { initializePodcastPlayback, initializeVideoPlayback };
