import { h } from 'preact';
import { GithubRepos } from '../githubRepos/githubRepos';
import { render } from '@utilities/preact/render';

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
