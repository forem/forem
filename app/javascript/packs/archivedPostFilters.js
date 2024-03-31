function initializeArchivedPostFilter() {
  const link = document.getElementById('toggleArchivedLink');
  if (link) {
    link.addEventListener('click', toggleArchivedPosts);
  }
}

function archivedPosts() {
  return document.getElementsByClassName('story-archived');
}

function showArchivedPosts() {
  const posts = archivedPosts();

  for (let i = 0; i < posts.length; i += 1) {
    posts[i].classList.remove('hidden');
  }
}

function hideArchivedPosts() {
  const posts = archivedPosts();

  for (let i = 0; i < posts.length; i += 1) {
    posts[i].classList.add('hidden');
  }
}

function toggleArchivedPosts(e) {
  e.preventDefault();
  const link = e.target;

  if (link.innerHTML.match(/Show/)) {
    link.innerHTML = 'Hide archived';
    showArchivedPosts();
  } else {
    link.innerHTML = 'Show archived';
    hideArchivedPosts();
  }
}

initializeArchivedPostFilter();
