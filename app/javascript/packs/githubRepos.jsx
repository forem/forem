import { h, render } from 'preact';
import { GithubRepos } from '../githubRepos/githubRepos';

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('github-repos-container');

  render(<GithubRepos />, root, root.firstElementChild);
});
