'use strict';

function archivedPosts() {
  return document.getElementsByClassName('story-archived');
}

function showArchivedPosts() {
  var posts = archivedPosts();

  for (var i = 0; i < posts.length; i += 1) {
    posts[i].classList.remove('hidden');
  }
}

function hideArchivedPosts() {
  var posts = archivedPosts();

  for (var i = 0; i < posts.length; i += 1) {
    posts[i].classList.add('hidden');
  }
}

function toggleArchivedPosts(e) {
  var link = e.target;

  if (link.innerHTML.match(/Show/)) {
    link.innerHTML = 'Hide archived';
    showArchivedPosts();
  } else {
    link.innerHTML = 'Show archived';
    hideArchivedPosts();
  }
}

function initializeArchivedPostFilter() {
  var link = document.getElementById('toggleArchivedLink');
  if (link) {
    link.addEventListener('click', toggleArchivedPosts);
  }
}
