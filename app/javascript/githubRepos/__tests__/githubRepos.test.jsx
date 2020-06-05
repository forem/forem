import { h } from 'preact';
import { render, waitForElement } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { axe } from 'jest-axe';
import { GithubRepos } from '../githubRepos';

global.fetch = fetch;

// TODO: Add tests when GitHub repositories are retrieved

describe('<GithubRepos />', () => {
  it('should not have any a11y violations', async () => {
    const { container } = render(<GithubRepos />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render with no repositories', () => {
    const { getByTitle } = render(<GithubRepos />);

    getByTitle('Loading GitHub repositories');
  });

  it('should render error message when repositories cannot be loaded', () => {
    fetch.mockReject('some error');
    const { getByRole } = render(<GithubRepos />);

    waitForElement(() => getByRole('alert'));
  });
});
