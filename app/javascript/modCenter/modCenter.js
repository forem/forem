export function toggleInboxTags() {
  const currentViewHeading = document.querySelector('.current-view-heading');
  const inboxTags = Array.from(document.querySelectorAll('.inbox-tags'));
  const tagHash = document.querySelector('.tag-hash');

  const removeTagHighlights = (tags) => {
    tags.forEach((tag) => {
      tag.classList.remove('crayons-link--current');
    });
  };
  const toggleTagHash = (tagName) => {
    if (tagName === 'All topics') {
      tagHash.classList.add('hidden');
    } else {
      tagHash.classList.remove('hidden');
    }
  };

  inboxTags.forEach((tag) => {
    tag.addEventListener('click', () => {
      removeTagHighlights(inboxTags);
      tag.classList.add('crayons-link--current');
      toggleTagHash(tag.dataset.tagName);
      currentViewHeading.textContent = tag.dataset.tagName;
    });
  });
}

export function initializeModCenterFunctions() {
  toggleInboxTags();
}
