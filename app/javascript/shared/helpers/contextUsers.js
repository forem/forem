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

  // 2. Direct Comment Thread Ancestors (always prioritize exact reply chain)
  if (targetNode) {
    let current = targetNode;
    while (current) {
      if (current.dataset && current.dataset.contentUserId) {
        ids.add(current.dataset.contentUserId);
      }
      current = current.parentElement?.closest('.single-comment-node');
    }
  }

  // 3. Broad Page Context (backfill up to 50)
  if (ids.size < 50) {
    const allCommentNodes = document.querySelectorAll('[data-content-user-id]');
    for (const node of allCommentNodes) {
      if (node.dataset.contentUserId) {
        ids.add(node.dataset.contentUserId);
        if (ids.size >= 50) break;
      }
    }
  }

  return Array.from(ids).map(id => parseInt(id, 10)).filter(id => !isNaN(id));
}
