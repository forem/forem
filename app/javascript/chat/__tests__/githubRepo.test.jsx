import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import GithubRepo from '../githubRepo';

global.fetch = fetch;

function flushPromises() {
  return new Promise(resolve => setImmediate(resolve));
}

const getGithubRepo = token => (
  <GithubRepo
    activeChannelId={12345}
    pusherKey="ASDFGHJKL"
    githubToken={token}
    resource={{ args: 'someargs' }}
  />
);

const contents = [
  {
    name: 'Camera',
    path: 'Camera',
    sha: 'hysst5jI2idHutihWo3JxYlTByoj0lkdXmkmuBEp',
    size: 0,
    url:
      'https://api.github.com/repos/username/repositoryname/contents/Camera?ref=master',
    html_url: 'https://github.com/username/repositoryname/tree/master/Camera',
    git_url:
      'https://api.github.com/repos/username/repositoryname/git/trees/hysst5jI2idHutihWo3JxYlTByoj0lkdXmkmuBEp',
    download_url: null,
    type: 'dir',
    _links: {
      self:
        'https://api.github.com/repos/username/repositoryname/contents/Camera?ref=master',
      git:
        'https://api.github.com/repos/username/repositoryname/git/trees/hysst5jI2idHutihWo3JxYlTByoj0lkdXmkmuBEp',
      html: 'https://github.com/username/repositoryname/tree/master/Camera',
    },
  },
  {
    name: 'Environment',
    path: 'Environment',
    sha: 'dwogYlYGQOXj1ru3L9HYfX7HdX3WNQPJgJVeStRs',
    size: 0,
    url:
      'https://api.github.com/repos/username/repositoryname/contents/Environment?ref=master',
    html_url:
      'https://github.com/username/repositoryname/tree/master/Environment',
    git_url:
      'https://api.github.com/repos/username/repositoryname/git/trees/dwogYlYGQOXj1ru3L9HYfX7HdX3WNQPJgJVeStRs',
    download_url: null,
    type: 'dir',
    _links: {
      self:
        'https://api.github.com/repos/username/repositoryname/contents/Environment?ref=master',
      git:
        'https://api.github.com/repos/username/repositoryname/git/trees/dwogYlYGQOXj1ru3L9HYfX7HdX3WNQPJgJVeStRs',
      html:
        'https://github.com/username/repositoryname/tree/master/Environment',
    },
  },
  {
    name: 'Interactables',
    path: 'Interactables',
    sha: '44OLxtYSQjr2DLVKPnwGTj6JuQpo7Te7pEIDULat',
    size: 0,
    url:
      'https://api.github.com/repos/username/repositoryname/contents/Interactables?ref=master',
    html_url:
      'https://github.com/username/repositoryname/tree/master/Interactables',
    git_url:
      'https://api.github.com/repos/username/repositoryname/git/trees/44OLxtYSQjr2DLVKPnwGTj6JuQpo7Te7pEIDULat',
    download_url: null,
    type: 'dir',
    _links: {
      self:
        'https://api.github.com/repos/username/repositoryname/contents/Interactables?ref=master',
      git:
        'https://api.github.com/repos/username/repositoryname/git/trees/44OLxtYSQjr2DLVKPnwGTj6JuQpo7Te7pEIDULat',
      html:
        'https://github.com/username/repositoryname/tree/master/Interactables',
    },
  },
  {
    name: 'Level Design',
    path: 'Level Design',
    sha: 'g178Oy2xV8gqFBhoaflJkSbHN01dxWEqjJTxw6Ax',
    size: 583,
    url:
      'https://api.github.com/repos/username/repositoryname/contents/Level%20Design?ref=master',
    html_url:
      'https://github.com/username/repositoryname/tree/master/Level%20Design',
    git_url:
      'https://api.github.com/repos/username/repositoryname/git/trees/g178Oy2xV8gqFBhoaflJkSbHN01dxWEqjJTxw6Ax',
    download_url:
      'https://raw.githubusercontent.com/username/repositoryname/master/Level%20Design',
    type: 'file',
    _links: {
      self:
        'https://api.github.com/repos/username/repositoryname/contents/Level%20Design?ref=master',
      git:
        'https://api.github.com/repos/username/repositoryname/git/trees/g178Oy2xV8gqFBhoaflJkSbHN01dxWEqjJTxw6Ax',
      html:
        'https://github.com/username/repositoryname/tree/master/Level%20Design',
    },
  },
  {
    name: 'Player',
    path: 'Player',
    sha: 'tia6ISq19krmOJzbtwpCTIuwRnvpSxZY2g1FMgOp',
    size: 1000,
    url:
      'https://api.github.com/repos/username/repositoryname/contents/Player?ref=master',
    html_url: 'https://github.com/username/repositoryname/tree/master/Player',
    git_url:
      'https://api.github.com/repos/username/repositoryname/git/trees/tia6ISq19krmOJzbtwpCTIuwRnvpSxZY2g1FMgOp',
    download_url:
      'https://raw.githubusercontent.com/username/repositoryname/master/Player',
    type: 'file',
    _links: {
      self:
        'https://api.github.com/repos/username/repositoryname/contents/Player?ref=master',
      git:
        'https://api.github.com/repos/username/repositoryname/git/trees/tia6ISq19krmOJzbtwpCTIuwRnvpSxZY2g1FMgOp',
      html: 'https://github.com/username/repositoryname/tree/master/Player',
    },
  },
];

describe('<GithubRepo />', () => {
  describe('with no token', () => {
    it('should render and test snapshot', () => {
      const tree = render(getGithubRepo());
      expect(tree).toMatchSnapshot();
    });

    it('should have the proper elements, attributes and values', () => {
      const context = shallow(getGithubRepo());
      expect(context.find('.activecontent__githubrepo').exists()).toEqual(true);
      expect(context.find('em').text()).toEqual('Authentication required');
    });
  });

  describe('with fake token', () => {
    it('should render and test snapshot', async () => {
      await fetch.mockResponseOnce(JSON.stringify(contents));
      const context = shallow(getGithubRepo('some_token'));
      await flushPromises();
      expect(context).toMatchSnapshot();
    });

    it('should have the proper elements, attributes and values with states set', async () => {
      await fetch.mockResponseOnce(JSON.stringify(contents));
      const context = shallow(getGithubRepo('some_token'));
      await flushPromises();

      const len = context.find('.activecontent__githubrepofilerow').length;
      expect(len > 0).toEqual(true);
      for (let i = 0; i < len; i += 1) {
        const ghrow = context.find('.activecontent__githubrepofilerow').at(i);
        expect(ghrow.exists()).toEqual(true);
        if (contents[i].type === 'dir') {
          expect(ghrow.text()).toEqual(`📁 ${contents[i].name}`);
        } else {
          expect(ghrow.text()).toEqual(contents[i].name);
        }
        expect(ghrow.childAt(0).attr('href')).toEqual(contents[i].html_url);
        expect(ghrow.childAt(0).attr('data-api-url')).toEqual(contents[i].url);
        expect(ghrow.childAt(0).attr('data-path')).toEqual(contents[i].path);
      }
      expect(context.find('.activecontent__githubrepoheader').text()).toEqual(
        context.state('path'),
      );
    });
  });
});
