export function gatherPriorityUserIds(targetNode) {
  const ids = new Set();
  
  // 1. Article Authors
  const articleContainer = document.getElementById('article-show-container');
  if (articleContainer) {
    if (articleContainer.dataset.authorId) {
      ids.add(articleContainer.dataset.authorId);
    }
    if (articleContainer.dataset.coAuthorIds) {
      const coAuthors = articleContainer.dataset.coAuthorIds.split(',').filter(Boolean);
      coAuthors.forEach(id => ids.add(id));
    }
  }

  // 2. Direct Comment Thread Ancestors
  if (targetNode) {
    let current = targetNode;
    while (current) {
      if (current.dataset && current.dataset.contentUserId) {
        ids.add(current.dataset.contentUserId);
      }
      current = current.parentElement?.closest('.single-comment-node');
    }
  }

  return Array.from(ids).map(id => parseInt(id, 10)).filter(id => !isNaN(id));
}
