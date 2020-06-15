import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import render from 'preact-render-to-json';
import fetch from 'jest-fetch-mock';
import { GithubRepos } from '../githubRepos';

global.fetch = fetch;

describe('<GithubRepos />', () => {
  describe('when there are no repos loaded yet', () => {
    it('should render and match the snapshot', () => {
      const tree = render(<GithubRepos />);
      expect(tree).toMatchSnapshot();
    });

    it('should have the loading div', () => {
      const context = shallow(<GithubRepos />);
      expect(context.find('.loading-repos')[0].attributes.className).toEqual(
        'github-repos loading-repos',
      );
    });
  });

  describe('when there was an error in the response', () => {
    it('renders and matches the snapshot', () => {
      fetch.mockReject('some error');
      const context = shallow(<GithubRepos />);
      context.setState({ error: true, errorMessage: 'this is an error' });
      context.rerender();
      const tree = render(context);
      expect(tree).toMatchSnapshot();
    });
  });
});
