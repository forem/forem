export function highlightCurrentTag() {
  // Grab content of current-view-heading
  // trim any # signs
  // loop through inbox tags, checking if the tag === current heading
  // if equal, apply crayon-link--current class to that tag

  const tagView = document
    .querySelector('.tag-view')
    .textContent.replace('#', '')
    .trim();
  const inboxTags = Array.from(document.querySelectorAll('.inbox-tags'));

  // eslint-disable-next-line no-plusplus
  for (let i = 0; i < inboxTags.length; i++) {
    if (inboxTags[i].dataset.tagName === tagView) {
      inboxTags[i].classList.add('crayons-link--current');
      return;
    }
  }
}

export function initializeModCenterFunctions() {
  highlightCurrentTag();
}
