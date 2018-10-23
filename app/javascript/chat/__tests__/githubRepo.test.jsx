import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import GithubRepo from '../githubRepo';

const getGithubRepo = token => (
  <GithubRepo
    activeChannelId={12345}
    pusherKey="ASDFGHJKL"
    githubToken={token}
    resource={{ args: 'someargs' }}
  />
);

describe('<GithubRepo />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getGithubRepo('QWERTYUIOP'));
    expect(tree).toMatchSnapshot();
  });

  it('should render and test snapshot (no github token)', () => {
    const tree = render(getGithubRepo(''));
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper attributes (no github token)', () => {
    const context = shallow(getGithubRepo());
    expect(context.find('.activecontent__githubrepo').exists()).toEqual(true);
    expect(context.find('em').text()).toEqual('Authentication required');
  });
});
