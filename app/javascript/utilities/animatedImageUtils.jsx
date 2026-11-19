import { h, render } from 'preact';
import Freezeframe from 'freezeframe';
import { Icon, ButtonNew as Button } from '@crayons';
import Play from '@images/play.svg';
import Pause from '@images/pause.svg';

let nextAnimatedImageId = 0;

const toggleGifButtonPressedState = (button) => {
  if (!button) {
    return;
  }
  const currentlyPressed = button.getAttribute('aria-pressed') === 'true';
  button.setAttribute('aria-pressed', !currentlyPressed);
};

/**
 * Helper function that will initialize play/pause functionality for any image with the attribute data-animated="true"
 */
export const initializePausableAnimatedImages = (animatedImages = []) => {
  if (!animatedImages || animatedImages.length === 0) {
    return;
  }

  const freezeframes = [];

  for (let i = 0; i < animatedImages.length; i += 1) {
    const image = animatedImages[i];
    if (
      !image ||
      !image.isConnected ||
      image.dataset.animatedInitialized === 'true' ||
      image.closest('.ff-container')
    ) {
      continue;
    }

    image.dataset.animatedInitialized = 'true';
    const imageId =
      image.getAttribute('id') || `animated-${nextAnimatedImageId}`;
    nextAnimatedImageId += 1;
    image.setAttribute('id', imageId);

    // Remove any surrounding link for the image so clicking toggles play/pause instead of navigating.
    const parentLink = image.closest('a');
    if (parentLink) {
      parentLink.replaceWith(image);
    }

    freezeframes.push(
      new Freezeframe({
        selector: `img[id='${imageId}']`,
        responsive: false,
        trigger: 'click',
      }),
    );
  }

  if (freezeframes.length === 0) {
    return;
  }

  const mainElement = document.querySelector('main');
  if (!mainElement) {
    return;
  }

  let disconnected = false;
  let readyWatcher = null;

  const disconnectWatcher = () => {
    if (disconnected) {
      return;
    }
    disconnected = true;
    if (readyWatcher) {
      readyWatcher.disconnect();
    }
    window.removeEventListener('beforeunload', disconnectWatcher);
  };

  const handleFreezeframeReadyState = () => {
    // Check if freezeframe has finished initializing all newly registered instances.
    const allReady = freezeframes.every((ff) => {
      const container = ff.items?.[0]?.$container;
      return container?.classList?.contains('ff-ready');
    });

    if (!allReady) {
      const initializedFrames = mainElement.querySelectorAll(
        '.ff-container.ff-ready',
      );
      if (initializedFrames.length < freezeframes.length) {
        return;
      }
    }

    disconnectWatcher();

    // Freezeframes are "paused" by default. If a user's settings allow, we immediately restart the animation.
    const okWithMotion = window.matchMedia(
      '(prefers-reduced-motion: no-preference)',
    ).matches;

    freezeframes.forEach((ff) => {
      const ffWrapper = ff.items?.[0]?.$container;
      if (!ffWrapper) {
        return;
      }

      if (okWithMotion) {
        ff.start();
      }

      // Freezeframe doesn't allow gifs to be stopped by keyboard press, so we add a button to handle it
      if (!ffWrapper.querySelector('.gif-button')) {
        ffWrapper.addEventListener('click', ({ currentTarget }) =>
          toggleGifButtonPressedState(
            currentTarget.querySelector('.gif-button'),
          ),
        );

        render(
          <Button
            aria-label="Pause animation playback"
            aria-pressed={!okWithMotion}
            className="gif-button fs-s gap-2"
            onClick={() => ff.toggle()}
          >
            <Icon src={Play} className="gif-play" />
            <Icon src={Pause} className="gif-pause" />
            GIF
          </Button>,
          ffWrapper,
        );
      }
    });
  };

  // Freezeframe initializes asynchronously, but unfortunately doesn't offer a callback for when it's "ready".
  // This mutation observer allows us to complete some final tasks when it's complete.
  readyWatcher = new MutationObserver(handleFreezeframeReadyState);
  readyWatcher.observe(mainElement, {
    subtree: true,
    attributes: true,
    attributeFilter: ['class'],
  });

  window.addEventListener('beforeunload', disconnectWatcher, { once: true });
  if (window.InstantClick?.on) {
    window.InstantClick.on('change', disconnectWatcher);
  }
};
