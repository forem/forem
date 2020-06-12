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
