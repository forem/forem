import { h } from 'preact';
import { GithubRepos } from '../githubRepos/githubRepos';
import { instantClickRender } from '@utilities/preact/render';

function loadElement() {
  const root = document.getElementById('github-repos-container');
  if (root) {
    instantClickRender(<GithubRepos />, root);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
