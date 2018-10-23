import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import marked from 'marked';
import GithubRepo from '../githubRepo';

global.fetch = fetch;

// const notfoundResponse = JSON.stringify([{ message: 'Not Found' }]);

const githubSampleReponse = JSON.stringify([
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
  {
    name: 'README.md',
    path: 'README.md',
    sha: 'JOkJF69EVq1Xfv32rBmU0nQF5poBNzqM8SGvV0BX',
    size: 970,
    url:
      'https://api.github.com/repos/username/repositoryname/contents/README.md?ref=master',
    html_url:
      'https://github.com/username/repositoryname/blob/master/README.md',
    git_url:
      'https://api.github.com/repos/username/repositoryname/git/blobs/JOkJF69EVq1Xfv32rBmU0nQF5poBNzqM8SGvV0BX',
    download_url:
      'https://raw.githubusercontent.com/username/repositoryname/master/README.md',
    type: 'file',
    _links: {
      self:
        'https://api.github.com/repos/username/repositoryname/contents/README.md?ref=master',
      git:
        'https://api.github.com/repos/username/repositoryname/git/blobs/JOkJF69EVq1Xfv32rBmU0nQF5poBNzqM8SGvV0BX',
      html: 'https://github.com/username/repositoryname/blob/master/README.md',
    },
  },
]);

const getGithubRepo = token => (
  <GithubRepo
    activeChannelId={12345}
    pusherKey="ASDFGHJKL"
    githubToken={token}
    resource={{ args: 'someargs' }}
  />
);

describe('<GithubRepo />', () => {
  describe('with no token', () => {
    it('should render and test snapshot', () => {
      fetch.mockResponse(githubSampleReponse);
      const tree = render(getGithubRepo());
      expect(tree).toMatchSnapshot();
    });
    it('should have the proper elements, attributes and values', () => {
      fetch.mockResponse(githubSampleReponse);
      const context = shallow(getGithubRepo());
      expect(context.find('.activecontent__githubrepo').exists()).toEqual(true);
      expect(context.find('em').text()).toEqual('Authentication required');
    });
  });

  describe('with fake token', () => {
    it('should render and test snapshot', () => {
      fetch.mockResponse(githubSampleReponse);
      const tree = render(getGithubRepo('some_token'));
      expect(tree).toMatchSnapshot();
    });

    it('should have the proper elements, attributes and values with setstates', async () => {
      fetch.mockResponse(githubSampleReponse);
      const context = await deep(getGithubRepo('some_token'));
      const dirs = [
        {
          name: 'Camera',
          path: 'Camera',
          sha: 'hysst5jI2idHutihWo3JxYlTByoj0lkdXmkmuBEp',
          size: 0,
          url:
            'https://api.github.com/repos/username/repositoryname/contents/Camera?ref=master',
          html_url:
            'https://github.com/username/repositoryname/tree/master/Camera',
          git_url:
            'https://api.github.com/repos/username/repositoryname/git/trees/hysst5jI2idHutihWo3JxYlTByoj0lkdXmkmuBEp',
          download_url: null,
          type: 'dir',
          _links: {
            self:
              'https://api.github.com/repos/username/repositoryname/contents/Camera?ref=master',
            git:
              'https://api.github.com/repos/username/repositoryname/git/trees/hysst5jI2idHutihWo3JxYlTByoj0lkdXmkmuBEp',
            html:
              'https://github.com/username/repositoryname/tree/master/Camera',
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
      ];
      context.setState({ directories: dirs });
      const fils = [
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
          html_url:
            'https://github.com/username/repositoryname/tree/master/Player',
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
            html:
              'https://github.com/username/repositoryname/tree/master/Player',
          },
        },
      ];
      context.setState({ files: fils });
      const dirsfils = dirs.concat(fils);
      context.setState({ readme: 'SOMETHING READ ME BLAHHHH' });
      context.setState({ root: true });
      context.rerender();

      const tree = render(context);
      expect(tree).toMatchSnapshot();

      const len = context.find('.activecontent__githubrepofilerow').length;
      for (let i = 0; i < len; i += 1) {
        const ghrow = context.find('.activecontent__githubrepofilerow').at(i);
        expect(ghrow.exists()).toEqual(true);
        if (dirsfils[i].type === 'dir') {
          expect(ghrow.text()).toEqual(`📁 ${dirsfils[i].name}`);
        } else {
          expect(ghrow.text()).toEqual(dirsfils[i].name);
        }
        expect(ghrow.childAt(0).attr('href')).toEqual(dirsfils[i].html_url);
        expect(ghrow.childAt(0).attr('data-api-url')).toEqual(dirsfils[i].url);
        expect(ghrow.childAt(0).attr('data-path')).toEqual(dirsfils[i].path);
      }
      expect(context.find('.activecontent__githubrepoheader').text()).toEqual(
        context.state('path'),
      );
      expect(
        context
          .find('.activecontent__githubrepo')
          .childAt(2)
          .attr('dangerouslySetInnerHTML'),
      ).toEqual({ __html: `${marked(context.state('readme'))}` });
    });
  });

  // describe('github API reponse stubbed and set state', () => {
  //   it('thingo ', () => {
  //     fetch.mockResponse(githubSampleReponse);
  //     const context = deep(getGithubRepo('some_token'));
  //
  //   });
  // });
});
