// the term billboard can be synonymously interchanged with displayAd
async function getBillboard() {
  const placeholderElement = document.getElementsByClassName(
    'js-display-ad-comments-container',
  )[0];

  // const {
  //   jsArticleId: articleId,
  // } = placeholderElement.dataset;

  const jsArticleId = placeholderElement.dataset.articleId;

  if (placeholderElement.innerHTML.trim() === '') {
    const response = await window.fetch(
      `/async_info/display_ads?articleId=${jsArticleId}`,
    );
    const htmlContent = await response.text();

    const generatedElement = document.createElement('div');
    generatedElement.innerHTML = htmlContent;

    placeholderElement.appendChild(generatedElement);
  }
}

getBillboard();
