import { setupDisplayAdDropdown } from '../utilities/displayAdDropdown';

// the term billboard can be synonymously interchanged with displayAd
async function getBillboard() {
  const placeholderElement = document.getElementsByClassName(
    'js-display-ad-comments-container',
  )[0];

  const { asyncUrl } = placeholderElement.dataset || {};

  if (placeholderElement.innerHTML.trim() === '') {
    const response = await window.fetch(`${asyncUrl}`);
    const htmlContent = await response.text();

    const generatedElement = document.createElement('div');
    generatedElement.innerHTML = htmlContent;

    placeholderElement.appendChild(generatedElement);
    setupDisplayAdDropdown();
  }
}

getBillboard();
