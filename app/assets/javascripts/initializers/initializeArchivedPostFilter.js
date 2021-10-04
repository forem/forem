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
  e.preventDefault();
  var link = e.target;

  if (link.innerHTML.match(i18next.t('archivedPosts.show_regexp'))) {
    link.innerHTML = i18next.t('archivedPosts.hide');
    showArchivedPosts();
  } else {
    link.innerHTML = i18next.t('archivedPosts.show');
    hideArchivedPosts();
  }
}

function initializeArchivedPostFilter() {
  var link = document.getElementById('toggleArchivedLink');
  if (link) {
    link.addEventListener('click', toggleArchivedPosts);
  }
}
