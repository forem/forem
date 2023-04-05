// the term billboard can be synonymously interchanged with displayAd
async function getBillboard() {
  const placeholderElement = document.getElementsByClassName(
    'js-display-ad-comments-container',
  )[0];

  const { articleId, placementArea } = placeholderElement.dataset || {};

  if (placeholderElement.innerHTML.trim() === '') {
    const response = await window.fetch(
      `/display_ads/for_display?article_id=${articleId}&placement_area=${placementArea}`,
    );
    const htmlContent = await response.text();

    const generatedElement = document.createElement('div');
    generatedElement.innerHTML = htmlContent;

    placeholderElement.appendChild(generatedElement);
  }
}

getBillboard();
