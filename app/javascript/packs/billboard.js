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
      observeBillboards();
    } catch (error) {
      if (!/NetworkError/i.test(error.message)) {
        Honeybadger.notify(error);
      }
    }
  }
}

function executeBBScripts(el) {
  const scriptElementsInDOM = el.getElementsByTagName('script');
  const scriptElementsToCopy = [];
  let originalElement, copyElement, parentNode, nextSibling, i;

  for (i = 0; i < scriptElementsInDOM.length; i++) {
    scriptElementsToCopy.push(scriptElementsInDOM[i]);
  }

  for (i = 0; i < scriptElementsToCopy.length; i++) {
    originalElement = scriptElementsToCopy[i];
    if (!originalElement) {
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
