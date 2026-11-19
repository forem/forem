import Freezeframe from 'freezeframe';
import { initializePausableAnimatedImages } from '../animatedImageUtils';

jest.mock('freezeframe', () =>
  jest.fn().mockImplementation(({ selector }) => {
    const img = globalThis.document.querySelector(selector);
    const container = globalThis.document.createElement('div');
    container.className = 'ff-container';
    if (img && img.parentNode) {
      img.parentNode.insertBefore(container, img);
      container.appendChild(img);
    }
    return {
      items: [{ $container: container }],
      start: jest.fn(),
      toggle: jest.fn(),
    };
  }),
);

describe('initializePausableAnimatedImages', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    document.body.innerHTML = '';
    window.matchMedia = jest.fn().mockReturnValue({ matches: true });
  });

  it('unwraps linked animated images and mounts the pause button when Freezeframe becomes ready', async () => {
    document.body.innerHTML = `
      <main id="main-content">
        <a href="https://example.com/anim.gif">
          <img src="https://example.com/anim.gif" data-animated="true" alt="Animated demo" />
        </a>
      </main>
    `;

    const images = document.querySelectorAll('[data-animated="true"]');
    initializePausableAnimatedImages(images);

    expect(document.querySelector('main a')).toBeNull();
    expect(Freezeframe).toHaveBeenCalledTimes(1);

    const ffInstance = Freezeframe.mock.results[0].value;
    const container = document.querySelector('.ff-container');
    container.classList.add('ff-ready');

    await Promise.resolve();
    await new Promise((resolve) => {
      setTimeout(resolve, 0);
    });

    expect(ffInstance.start).toHaveBeenCalledTimes(1);
    expect(container.querySelector('.gif-button')).not.toBeNull();
  });

  it('handles animated images that are not wrapped in an anchor tag without throwing', () => {
    document.body.innerHTML = `
      <main id="main-content">
        <div class="article-body">
          <img src="https://example.com/standalone.gif" data-animated="true" alt="Standalone gif" />
        </div>
      </main>
    `;

    const images = document.querySelectorAll('[data-animated="true"]');
    expect(() => initializePausableAnimatedImages(images)).not.toThrow();
    expect(Freezeframe).toHaveBeenCalledTimes(1);
    expect(images[0].dataset.animatedInitialized).toBe('true');
  });

  it('is idempotent when re-executed on restored InstantClick history DOM (popstate back/forward)', () => {
    document.body.innerHTML = `
      <main id="main-content">
        <a href="https://example.com/anim.gif">
          <img src="https://example.com/anim.gif" data-animated="true" alt="Animated demo" />
        </a>
      </main>
    `;

    initializePausableAnimatedImages(
      document.querySelectorAll('[data-animated="true"]'),
    );
    expect(Freezeframe).toHaveBeenCalledTimes(1);

    // Simulate InstantClick popstate restoring #page-content and re-running articleAnimations.jsx
    expect(() =>
      initializePausableAnimatedImages(
        document.querySelectorAll('[data-animated="true"]'),
      ),
    ).not.toThrow();
    expect(Freezeframe).toHaveBeenCalledTimes(1);
  });

  it('safely skips disconnected images or missing <main> containers', () => {
    const detachedImg = document.createElement('img');
    detachedImg.setAttribute('data-animated', 'true');

    expect(() => initializePausableAnimatedImages([detachedImg])).not.toThrow();
    expect(Freezeframe).not.toHaveBeenCalled();
  });
});
