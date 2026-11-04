import { h, render } from 'preact';
import { GithubRepos } from '../githubRepos/githubRepos';

function loadElement() {
  const root = document.getElementById('github-repos-container');
  if (root) {
    const { organizations, maxOrganizations } = root.dataset;
    render(
      <GithubRepos
        organizations={JSON.parse(organizations)}
        maxOrganizations={Number(maxOrganizations)}
      />,
      root,
    );
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
