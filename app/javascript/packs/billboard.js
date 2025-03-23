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


      // *** Beginning of where we guard against disallowed attributes
      const allowedAttributes = new Set([
        "class",
        "style",
        "data-display-unit",
        "data-id",
        "data-category-click",
        "data-category-impression",
        "data-context-type",
        "data-special",
        "data-article-id",
        "data-impression-recorded",
        "data-type-of"
      ]);
      
      // Callback to process attribute mutations
      function handleAttributeMutations(mutations) {
        mutations.forEach(mutation => {
          if (mutation.type === "attributes") {
            const { attributeName, target } = mutation;
            if (!allowedAttributes.has(attributeName)) {
              // Remove any attribute that isn't allowed
              target.removeAttribute(attributeName);
            }
          }
        });
      }
      
      // Observer configuration for attribute changes only (no subtree on the element itself)
      const observerConfig = { attributes: true };
      
      // Attach a MutationObserver to a specific billboard element
      function observeThisBillboard(element) {
        // Avoid attaching multiple observers to the same element
        if (element.__billboardObserverAttached) return;
        const observer = new MutationObserver(handleAttributeMutations);
        observer.observe(element, observerConfig);
        // Mark the element so we don't attach another observer in the future
        element.__billboardObserverAttached = true;
      }
      
      // Initially attach observers to all existing billboard elements
      document.querySelectorAll('.js-billboard').forEach(observeThisBillboard);
      
      // To handle new billboard elements that are added dynamically,
      // observe the document body for added nodes.
      const bodyObserver = new MutationObserver(mutations => {
        mutations.forEach(mutation => {
          if (mutation.type === "childList") {
            mutation.addedNodes.forEach(node => {
              if (node.nodeType === Node.ELEMENT_NODE) {
                // If the added node itself is a billboard, attach an observer
                if (node.matches('.js-billboard')) {
                  observeThisBillboard(node);
                }
                // Also check if any descendants are billboards
                node.querySelectorAll && node.querySelectorAll('.js-billboard').forEach(observeThisBillboard);
              }
            });
          }
        });
      });
      
      bodyObserver.observe(document.body, { childList: true, subtree: true });

      // *** End of guarding against disallowed attributes

      observeBillboards();
    } catch (error) {
      if (!/NetworkError/i.test(error.message)) {
        Honeybadger.notify(error);
      }
    }
  }
}

getBillboard();
