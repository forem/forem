import { h, render } from 'preact';
import { GithubRepos } from '../githubRepos/githubRepos';

function loadElement() {
  const root = document.getElementById('github-repos-container');
  if (root) {
    render(<GithubRepos />, root);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
