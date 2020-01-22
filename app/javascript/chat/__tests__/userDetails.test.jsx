import { h } from 'preact';
import render from 'preact-render-to-json';
import { JSDOM } from 'jsdom';
import { shallow } from 'preact-render-spy';
import UserDetails from '../userDetails';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;
global.window.currentUser = { id: '1' };

const user1 = {
  id: '1',
  username: 'bojackhorseman',
  name: 'Bojack Horseman',
  summary: 'I am the Bojack Horseman from Horsing Around and Secreteriat',
  joined_at: 'January 2, 1964',
  twitter_username: 'bojacktwitter',
  github_username: 'bojackgithub',
  website_url: 'http://bojackhorseman.com',
  location: 'Los Angeles, CA',
  profile_image: 'https://media.giphy.com/media/3o7WTHb2WjEXbsmWDS/giphy.gif',
};

const user2 = {
  id: '2',
  username: 'mrpeanutbutter',
  name: 'Mr. Peanutbutter',
  summary: 'Woof Woof *smile*',
  joined_at: '1960s',
  twitter_username: 'mrpbtwitter',
  github_username: 'mrpbgithub',
  website_url: 'http://mrpeanutbutter.com',
  location: 'Los Angeles, DO(G)',
  profile_image: 'https://media.giphy.com/media/xThuW6sWCGbpZMpX7a/giphy.gif',
};

const channel = { channel_type: 'direct', id: 2 };

const getUserDetails = user => (
  <UserDetails user={user} activeChannel={channel} activeChannelId={2} />
);

describe('<UserDetails />', () => {
  describe('for user1', () => {
    it('should render and test snapshot', () => {
      const tree = render(getUserDetails(user1));
      expect(tree).toMatchSnapshot();
    });

    it('should have the appropriate elements, attributes and values', () => {
      const context = shallow(getUserDetails(user1));
      expect(
        context.find('.activechatchannel__activecontentuserdetails').exists(),
      ).toEqual(true); // only class to check for
      const parentDiv = context.find('div').at(0);

      expect(parentDiv.childAt(0)).toEqual(context.find('img').at(0));
      expect(
        context
          .find('img')
          .at(0)
          .attr('src'),
      ).toEqual(user1.profile_image); // profile pic

      expect(parentDiv.childAt(1)).toEqual(context.find('h1'));
      expect(context.find('h1').text()).toEqual(user1.name); // user.name
      expect(
        context
          .find('a')
          .at(0)
          .attr('href'),
      ).toEqual(`/${user1.username}`); // user.username

      expect(
        context
          .find('.userdetails__blockreport')
          .at(0)
          .children()[0],
      ).toEqual('');

      // social links
      expect(
        context
          .find('a')
          .at(1)
          .attr('href'),
      ).toEqual(`https://twitter.com/${user1.twitter_username}`); // twitter
      expect(
        context
          .find('a')
          .at(2)
          .attr('href'),
      ).toEqual(`https://github.com/${user1.github_username}`); // github
      expect(
        context
          .find('a')
          .at(3)
          .attr('href'),
      ).toEqual(user1.website_url); // website

      expect(parentDiv.childAt(3)).toEqual(context.find('div').at(2));
      expect(
        context
          .find('div')
          .at(2)
          .text(),
      ).toEqual(user1.summary); // user.summary
      expect(
        context
          .find('div')
          .at(6)
          .text(),
      ).toEqual(user1.location); // user.location
      expect(
        context
          .find('div')
          .at(8)
          .text(),
      ).toEqual(user1.joined_at); // user.joined_at
    });
  });

  describe('for user2', () => {
    it('should render and test snapshot', () => {
      const tree = render(getUserDetails(user2));
      expect(tree).toMatchSnapshot();
    });

    it('should have the appropriate elements, attributes and values', () => {
      const context = shallow(getUserDetails(user2));
      expect(
        context.find('.activechatchannel__activecontentuserdetails').exists(),
      ).toEqual(true); // only class to check for
      const parentDiv = context.find('div').at(0);

      expect(parentDiv.childAt(0)).toEqual(context.find('img').at(0));
      expect(
        context
          .find('img')
          .at(0)
          .attr('src'),
      ).toEqual(user2.profile_image); // profile pic

      expect(parentDiv.childAt(1)).toEqual(context.find('h1'));
      expect(context.find('h1').text()).toEqual(user2.name); // user.name
      expect(
        context
          .find('a')
          .at(0)
          .attr('href'),
      ).toEqual(`/${user2.username}`); // user.username

      expect(
        parentDiv
          .find('.userdetails__blockreport')
          .at(0)
          .childAt(0)
          .text(),
      ).toEqual('Block User');

      expect(
        parentDiv
          .find('.userdetails__blockreport')
          .at(0)
          .childAt(1)
          .text(),
      ).toEqual('Report Abuse');

      // social links
      expect(
        context
          .find('a')
          .at(1)
          .attr('href'),
      ).toEqual(`https://twitter.com/${user2.twitter_username}`); // twitter
      expect(
        context
          .find('a')
          .at(2)
          .attr('href'),
      ).toEqual(`https://github.com/${user2.github_username}`); // github
      expect(
        context
          .find('a')
          .at(3)
          .attr('href'),
      ).toEqual(user2.website_url); // website

      expect(parentDiv.childAt(3)).toEqual(context.find('div').at(2));
      expect(
        context
          .find('div')
          .at(2)
          .text(),
      ).toEqual(user2.summary); // user.summary
      expect(
        context
          .find('div')
          .at(6)
          .text(),
      ).toEqual(user2.location); // user.location
      expect(
        context
          .find('div')
          .at(8)
          .text(),
      ).toEqual(user2.joined_at); // user.joined_at
    });
  });
});
