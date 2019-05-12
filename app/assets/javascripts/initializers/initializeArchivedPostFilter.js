function showArchivedPosts() {
  var archivedPosts = document.getElementsByClassName(
    'single-article-archived',
  );

  for (var i = 0; i < archivedPosts.length; i += 1) {
    archivedPosts[i].classList.remove('hidden');
  }
}

function hideArchivedPosts() {
  var archivedPosts = document.getElementsByClassName(
    'single-article-archived',
  );

  for (var i = 0; i < archivedPosts.length; i += 1) {
    archivedPosts[i].classList.add('hidden');
  }
}

function toggleArchivedPosts(e) {
  var link = e.target;

  if (link.innerHTML.match(/Show/)) {
    link.innerHTML = 'Hide Archived';
    showArchivedPosts();
  } else {
    link.innerHTML = 'Show Archived';
    hideArchivedPosts();
  }
}

function initializeArchivedPostFilter() {
  var link = document.getElementById('toggleArchivedLink');

  link.addEventListener('click', toggleArchivedPosts);
}
