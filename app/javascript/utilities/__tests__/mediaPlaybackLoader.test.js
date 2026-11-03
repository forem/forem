import {
  shouldInitializePodcastPlayback,
  loadMediaPlaybackBundle,
  resetMediaPlaybackLoaderForTests,
} from '../mediaPlaybackLoader';

describe('mediaPlaybackLoader', () => {
  beforeEach(() => {
    resetMediaPlaybackLoaderForTests();
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    window.localStorage.clear();
    delete window.Forem;
    delete window.activeEpisode;
  });

  it('returns false when no podcast DOM elements or saved state exist', () => {
    expect(shouldInitializePodcastPlayback()).toBe(false);
  });

  it('returns true when a .record-wrapper or .podcastliquidtag__record element exists', () => {
    const record = document.createElement('button');
    record.className = 'record-wrapper';
    document.body.appendChild(record);

    expect(shouldInitializePodcastPlayback()).toBe(true);
  });

  it('returns true when localStorage contains an active media_playback_state_v3 session', () => {
    window.localStorage.setItem(
      'media_playback_state_v3',
      JSON.stringify({ playing: true, playbackName: 'ep-1', html: '<audio />' }),
    );

    expect(shouldInitializePodcastPlayback()).toBe(true);
  });

  it('returns false when media_playback_state_v3 is empty/uninitialized', () => {
    window.localStorage.setItem(
      'media_playback_state_v3',
      JSON.stringify({ playing: false, html: '' }),
    );

    expect(shouldInitializePodcastPlayback()).toBe(false);
  });

  it('loads the mediaPlayback bundle from the meta tag when needed', async () => {
    const meta = document.createElement('meta');
    meta.name = 'media-playback-script';
    meta.content = '/assets/mediaPlayback-test.js';
    document.head.appendChild(meta);

    const mockPodcastInit = jest.fn();
    const mockVideoInit = jest.fn();
    const promise = loadMediaPlaybackBundle();

    const script = document.querySelector(
      'script[src="/assets/mediaPlayback-test.js"]',
    );
    expect(script).not.toBeNull();

    window.Forem = {
      initializePodcastPlayback: mockPodcastInit,
      initializeVideoPlayback: mockVideoInit,
    };
    script.dispatchEvent(new Event('load'));

    await expect(promise).resolves.toEqual({
      initializePodcastPlayback: mockPodcastInit,
      initializeVideoPlayback: mockVideoInit,
    });
  });
});
