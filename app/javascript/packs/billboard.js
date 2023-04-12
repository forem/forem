import { setupDisplayAdDropdown } from '../utilities/displayAdDropdown';

// the term billboard can be synonymously interchanged with displayAd
async function getBillboard() {
  const placeholderElements = document.getElementsByClassName(
    'js-display-ad-container',
  );

  const promises = [...placeholderElements].map(generateDisplayAd);
  await Promise.all(promises);
}

async function generateDisplayAd(element) {
  const { asyncUrl } = element.dataset || {};

  if (element.innerHTML.trim() === '') {
    const response = await window.fetch(`${asyncUrl}`);
    const htmlContent = await response.text();

    const generatedElement = document.createElement('div');
    generatedElement.innerHTML = htmlContent;

    element.appendChild(generatedElement);
    setupDisplayAdDropdown();
  }
}

getBillboard();
