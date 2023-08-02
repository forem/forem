import { setupDisplayAdDropdown } from '../utilities/displayAdDropdown';
import { observeDisplayAds } from './billboardAfterRenderActions';

// the term billboard can be synonymously interchanged with displayAd
async function getBillboard() {
  const placeholderElements = document.getElementsByClassName(
    'js-display-ad-container',
  );

  const promises = [...placeholderElements].map(generateDisplayAd);
  await Promise.all(promises);
}

async function generateDisplayAd(element) {
  const { asyncUrl } = element.dataset;

  if (asyncUrl) {
    try {
      const response = await window.fetch(`${asyncUrl}`);
      const htmlContent = await response.text();

      const generatedElement = document.createElement('div');
      generatedElement.innerHTML = htmlContent;

      element.innerHTML = '';
      element.appendChild(generatedElement);
      setupDisplayAdDropdown();
      // This is called here because the ad is loaded asynchronously.
      // The original code is still in the asset pipeline, so is not importable.
      // This could be refactored to be importable as we continue that migration.
      // eslint-disable-next-line no-undef
      observeDisplayAds();
    } catch (error) {
      if (!/NetworkError/i.test(error.message)) {
        Honeybadger.notify(error);
      }
    }
  }
}

getBillboard();

export { getBillboard };
