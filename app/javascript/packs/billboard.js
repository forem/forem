import { setupBillboardDropdown } from '../utilities/billboardDropdown';
import {
  observeBillboards,
  executeBBScripts,
} from './billboardAfterRenderActions';

export async function getBillboard() {
  const placeholderElements = document.getElementsByClassName(
    'js-billboard-container',
  );

  const promises = [...placeholderElements].map(generateBillboard);
  await Promise.all(promises);
}

async function generateBillboard(element) {
  const { asyncUrl } = element.dataset;

  if (asyncUrl) {
    try {
      const response = await window.fetch(`${asyncUrl}`);
      const htmlContent = await response.text();

      const generatedElement = document.createElement('div');
      generatedElement.innerHTML = htmlContent;

      element.innerHTML = '';
      element.appendChild(generatedElement);
      executeBBScripts(element);
      setupBillboardDropdown();
      // This is called here because the ad is loaded asynchronously.
      // The original code is still in the asset pipeline, so is not importable.
      // This could be refactored to be importable as we continue that migration.
      // eslint-disable-next-line no-undef
      observeBillboards();
    } catch (error) {
      if (!/NetworkError/i.test(error.message)) {
        Honeybadger.notify(error);
      }
    }
  }
}

getBillboard();
