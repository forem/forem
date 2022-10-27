import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { axe } from 'jest-axe';
import { GithubRepos } from '../githubRepos';

global.fetch = fetch;
const csrfToken = 'this-is-a-csrf-token';
jest.mock('../../utilities/http/csrfToken', () => ({
  getCSRFToken: jest.fn(() => Promise.resolve(csrfToken)),
}));

function getRepositories() {
  return [
    {
      github_id_code: 152939052,
      name: 'Advanced-React',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 104694593,
      name: 'alfred-workflows',
      fork: false,
      featured: true,
    },
    {
      github_id_code: 233181839,
      name: 'awesome-uses',
      fork: true,
      featured: false,
    },
    { github_id_code: 50081961, name: 'b-flat', fork: false, featured: false },
    {
      github_id_code: 63587352,
      name: 'bcn-reactjs-storybook-talk-2016-07-25',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 186324758,
      name: 'codecopy',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 206377108,
      name: 'css-flexbox-cheatsheet',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 174367087,
      name: 'delegate-it',
      fork: false,
      featured: true,
    },
    {
      github_id_code: 185507633,
      name: 'delegate-it',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 226455664,
      name: 'dev-to-extension-pack',
      fork: false,
      featured: true,
    },
    { github_id_code: 247005219, name: 'dev.to', fork: true, featured: false },
    {
      github_id_code: 155133634,
      name: 'electron-quick-start-typescript',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 127831732,
      name: 'for-brad',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 159068803,
      name: 'gatsby-extension-pack',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 102166395,
      name: 'generator-minobo',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 94140199,
      name: 'js-montreal-storybook-talk-2017-06-13',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 214526372,
      name: 'learnstorybook.com',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 187306233,
      name: 'linkstate',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 217939653,
      name: 'magenta-sun',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 95490447,
      name: 'old_www.iamdeveloper.com',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 64718031,
      name: 'react-apps-with-typescript',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 209663349,
      name: 'react-base-table',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 48863418,
      name: 'react-slingshot',
      fork: false,
      featured: true,
    },
    {
      github_id_code: 260276850,
      name: 'redux-fun',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 168584034,
      name: 'refined-github',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 245753797,
      name: 'robust-petunia',
      fork: false,
      featured: true,
    },
    {
      github_id_code: 183524035,
      name: 'size-plugin',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 142638936,
      name: 'storybook',
      fork: true,
      featured: false,
    },
    { github_id_code: 148421088, name: 'tota11y', fork: true, featured: false },
    {
      github_id_code: 77359592,
      name: 'ts-preact-starter',
      fork: false,
      featured: true,
    },
    {
      github_id_code: 114836219,
      name: 'vscode-gatsby-snippets',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 147457108,
      name: 'vscode-preact-snippets',
      fork: false,
      featured: false,
    },
    {
      github_id_code: 169174116,
      name: 'webext-dynamic-content-scripts',
      fork: true,
      featured: false,
    },
    {
      github_id_code: 189917402,
      name: 'webext-options-sync',
      fork: true,
      featured: false,
    },
  ];
}

describe('<GithubRepos />', () => {
  beforeEach(() => {
    global.Honeybadger = { notify: jest.fn() };
  });

  it('should have no a11y violations', async () => {
    fetch.mockResponse(JSON.stringify(getRepositories()));

    const { container } = render(<GithubRepos />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render with repositories', async () => {
    fetch.mockResponse(JSON.stringify(getRepositories()));
    const { getByTitle, findByTestId } = render(<GithubRepos />);

    getByTitle('Loading GitHub repositories');

    const repoList = await findByTestId('github-repos-list');

    // No need to test it's contents as this is the <SingleRepo /> component
    // which has it's own tests.
    expect(repoList).toBeDefined();
  });

  it('should render with no repositories', () => {
    fetch.mockResponse('[]');
    const { queryByTitle } = render(<GithubRepos />);

    expect(queryByTitle('Loading GitHub repositories')).toBeDefined();
  });

  it('should render error message when repositories cannot be loaded', async () => {
    fetch.mockReject('some error');

    const { findByRole } = render(<GithubRepos />);
    const errorAlert = await findByRole('alert');

    expect(errorAlert.textContent).toEqual('An error occurred: some error');
    expect(Honeybadger.notify).toHaveBeenCalledTimes(1);
  });
});
