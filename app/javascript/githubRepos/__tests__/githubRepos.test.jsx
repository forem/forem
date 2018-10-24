import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import { GithubRepos } from '../githubRepos';

global.fetch = fetch;

describe('<GithubRepos />', () => {
  const fakeResponse = JSON.stringify([
    {
      github_id_code: 1,
      name: 'dev.to',
      fork: false,
      selected: false,
    },
    {
      github_id_code: 2,
      name: 'a forked repo',
      fork: true,
      selected: true,
    },
  ]);

  // describe('when there are no repos loaded yet', () => {
  //   it('renders properly', () => {
  //     fetch.mockResponse('[{}]')
  //     // const tree = render(<GithubRepos />)
  //     // expect(tree).toMatchSnapshot();
  //     const context = shallow(<GithubRepos />)
  //     expect(context.find('.loading-repos')[0].attributes.className).
  //       toEqual('github-repos loading-repos')
  //     expect(context.state('repos')).toEqual([]);
  //     expect(context.state('erroredOut')).toEqual(false);
  //   })
  // })

  // describe('when there is an error in the response', () => {
  //   it('renders the error message', () => {
  //     fetch.mockResponse('[{}]')
  //     const context = shallow(<GithubRepos />)
  //     console.log(context)
  //     expect(context.find('.github-repos-errored')[0].attributes.className).
  //       toEqual('github-repos github-repos-errored')
  //     expect(context.state('erroredOut')).toEqual(true);
  //     expect(context.state('repos')).toEqual([]);
  //   })
  // })

  describe('when it successfully gets the repos', () => {
    it('renders properly', () => {
      fetch.mockResponse(fakeResponse);
      const context = shallow(<GithubRepos />);

      // context.render()
      // console.log(context)
      // console.log(context.find('.github-repos'))
      expect(context.state()).toMatchSnapshot();
      // expect(context).toEqual(JSON.parse(fakeResponse))
    });
  });
});
