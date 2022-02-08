import { h, render } from 'preact';
import Freezeframe from 'freezeframe';
import { Icon, ButtonNew as Button } from '@crayons';
import Play from '@images/play.svg';
import Pause from '@images/pause.svg';

const toggleGifButtonPressedState = (button) => {
  const currentlyPressed = button.getAttribute('aria-pressed') === 'true';
  button.setAttribute('aria-pressed', !currentlyPressed);
};

/**
 * Helper function that will initialize play/pause functionality for any image with the attribute data-animated="true"
 */
export const initializePausableAnimatedImages = (animatedImages = []) => {
  if (animatedImages.length > 0) {
    const freezeframes = [];

    for (let i = 0; i < animatedImages.length; i++) {
      const image = animatedImages[i];
      // Give the image an ID so that we can uniquely target it in freezeframe
      image.setAttribute('id', `animated-${i}`);

      // Remove the surrounding links for the image, so it can be clicked to play/pause
      image.closest('a').outerHTML = image.outerHTML;

      freezeframes.push(
        new Freezeframe({
          selector: `img[id='animated-${i}']`,
          responsive: false,
          trigger: 'click',
        }),
      );
    }

    const handleFreezeframeReadyState = (_mutationList, observer) => {
      // Check if freezeframe has finished initializing
      const initializedFrames = document.querySelectorAll(
        '.ff-container.ff-ready',
      );

      if (initializedFrames.length < freezeframes.length) {
        // Not ready yet, do nothing
        return;
      }

      // Freezeframes are ready, and we can disconnect our observer
      observer.disconnect();

      // Freezeframes are "paused" by default. If a user's settings allow, we immediately restart the animation.
      const okWithMotion = window.matchMedia(
        '(prefers-reduced-motion: no-preference)',
      ).matches;

      freezeframes.forEach((ff) => {
        if (okWithMotion) {
          ff.start();
        }

        // Freezeframe doesn't allow gifs to be stopped by keyboard press, so we add a button to handle it
        const ffWrapper = ff.items[0]['$container'];

        // We want to update the button's state when the gif is paused by image/canvas click
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
      });
    };

    // Freezeframe initializes asynchronously, but unfortunately doesn't offer a callback for when it's "ready".
    // This mutation observer allows us to complete some final tasks when it's complete.
    const readyWatcher = new MutationObserver(handleFreezeframeReadyState);
    readyWatcher.observe(document.querySelector('main'), {
      subtree: true,
      attributes: true,
      attributeFilter: ['class'],
    });
  }
};
