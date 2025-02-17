import { setupBillboardInteractivity } from '../utilities/billboardInteractivity';
import {
  observeBillboards,
  executeBBScripts,
  implementSpecialBehavior,
} from './billboardAfterRenderActions';

export async function getBillboard() {
  const placeholderElements = document.getElementsByClassName(
    'js-billboard-container',
  );

  const promises = [...placeholderElements].map(generateBillboard);
  await Promise.all(promises);
}

async function generateBillboard(element) {
  let { asyncUrl } = element.dataset;
  const currentParams = window.location.href.split('?')[1];
  const cookieStatus = localStorage.getItem('cookie_status');
  if (currentParams && currentParams.includes('bb_test_placement_area')) {
    asyncUrl = `${asyncUrl}?${currentParams}`;
  }

  if (cookieStatus === 'allowed') {
    asyncUrl += `${asyncUrl.includes('?') ? '&' : '?'}cookies_allowed=true`;
  }


  if (asyncUrl) {
    try {
      // When context is digest we don't show this billboard
      // This is a hardcoded feature which should become more dynamic later.
      const contentElement = document.getElementById('page-content-inner');
      const isInternalNav = contentElement && contentElement.dataset.internalNav === 'true'
      const isNativeUserAgent = navigator.userAgent.includes('Forem');
      if (
        asyncUrl?.includes('post_fixed_bottom') &&
        (currentParams?.includes('context=digest') || isInternalNav || isNativeUserAgent)
      ) {     
        return;
      }

      const response = await window.fetch(asyncUrl);
      const htmlContent = await response.text();
      const generatedElement = document.createElement('div');
      generatedElement.innerHTML = htmlContent;
      element.innerHTML = '';
      element.appendChild(generatedElement);
      element.querySelectorAll('img').forEach((img) => {
        img.onerror = function () {
          this.style.display = 'none';
        };
      });
      const dismissalSku =
        element.querySelector('.js-billboard')?.dataset.dismissalSku;
      if (localStorage && dismissalSku && dismissalSku.length > 0) {
        const skuArray =
          JSON.parse(localStorage.getItem('dismissal_skus_triggered')) || [];
        if (skuArray.includes(dismissalSku)) {
          element.style.display = 'none';
          element.innerHTML = '';
        }
      }

      executeBBScripts(element);
      implementSpecialBehavior(element);
      setupBillboardInteractivity();
      // This is called here because the ad is loaded asynchronously.
      // The original code is still in the asset pipeline, so is not importable.
      // This could be refactored to be importable as we continue that migration.
      // eslint-disable-next-line no-undef

      document.querySelectorAll('.billboard-readmore-button').forEach((button) => {
        // If the card is shorter than 100vh - 200px we immediately hide the button and related classes
        if (button.closest('.crayons-card').querySelector('.text-styles').offsetHeight < window.innerHeight - 200) {
          button.closest('.crayons-card').querySelector('.text-styles').classList.remove('long-bb-body');
          button.closest('.crayons-card').querySelector('.long-bb-bottom').classList.add('hidden');
          button.closest('.crayons-card').querySelector('.billboard-readmore-button').classList.add('hidden');
        }

        button.addEventListener('click', () => {
          button.closest('.crayons-card').querySelector('.text-styles').classList.remove('long-bb-body');
          button.closest('.crayons-card').querySelector('.long-bb-bottom').classList.add('hidden');
          button.closest('.crayons-card').querySelector('.billboard-readmore-button').classList.add('hidden');
        });
      });  

      observeBillboards();
    } catch (error) {
      if (!/NetworkError/i.test(error.message)) {
        Honeybadger.notify(error);
      }
    }
  }
}

getBillboard();
