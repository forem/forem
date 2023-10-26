import { setupBillboardDropdown } from '../utilities/billboardDropdown';
import { observeBillboards } from './billboardAfterRenderActions';

async function getBillboard() {
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

function executeBBScripts(el) {
  // This is the same execute JS functionality we use for InstantClick
  // It's likely we could refactor this to by DRY — Rule of 3 for now.
  const scriptElementsInDOM = el.getElementsByTagName('script');
  const scriptElementsToCopy = [];
  let originalElement;
  let copyElement;
  let parentNode;
  let nextSibling;
  let i;

  for (i = 0; i < scriptElementsInDOM.length; i++) {
    if (scriptElementsInDOM[i].id === 'gist-ltag') continue;
    scriptElementsToCopy.push(scriptElementsInDOM[i]);
  }

  for (i = 0; i < scriptElementsToCopy.length; i++) {
    originalElement = scriptElementsToCopy[i];
    if (!originalElement) {
      // Might have disappeared, see previous comment
      continue;
    }
    if (originalElement.hasAttribute('data-no-instant')) {
      continue;
    }

    copyElement = document.createElement('script');
    for (let j = 0; j < originalElement.attributes.length; j++) {
      copyElement.setAttribute(
        originalElement.attributes[j].name,
        originalElement.attributes[j].value,
      );
    }
    copyElement.textContent = originalElement.textContent;

    parentNode = originalElement.parentNode;
    nextSibling = originalElement.nextSibling;
    parentNode.removeChild(originalElement);
    parentNode.insertBefore(copyElement, nextSibling);
  }
}

getBillboard();

export { getBillboard };
