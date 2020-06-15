export function highlightCurrentTag() {
  const tagView = document
    .querySelector('.tag-view')
    .textContent.replace('#', '')
    .trim();
  const inboxTags = Array.from(document.querySelectorAll('.inbox-tags'));

  for (let i = 0; i < inboxTags.length; i += 1) {
    if (inboxTags[i].dataset.tagName === tagView) {
      inboxTags[i].classList.add('crayons-link--current');
      return;
    }
  }
}

export function initializeModCenterFunctions() {
  highlightCurrentTag();
}
