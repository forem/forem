import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import UserDetails from '../userDetails';

const bojack = {
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

const mrpeanutbutter = {
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

const getUserDetails = user => <UserDetails user={user} />;

describe('<UserDetails />', () => {
  describe('for user bojack', () => {
    it('should render and test snapshot', () => {
      const tree = render(getUserDetails(bojack));
      expect(tree).toMatchSnapshot();
    });

    it('should have the appropriate elements, attributes and values', () => {
      const context = shallow(getUserDetails(bojack));
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
      ).toEqual(bojack.profile_image); // profile pic

      expect(parentDiv.childAt(1)).toEqual(context.find('h1'));
      expect(context.find('h1').text()).toEqual(bojack.name); // user.name
      expect(
        context
          .find('a')
          .at(0)
          .attr('href'),
      ).toEqual(`/${bojack.username}`); // user.username

      // social links
      expect(
        context
          .find('a')
          .at(1)
          .attr('href'),
      ).toEqual(`https://twitter.com/${bojack.twitter_username}`); // twitter
      expect(
        context
          .find('a')
          .at(2)
          .attr('href'),
      ).toEqual(`https://github.com/${bojack.github_username}`); // github
      expect(
        context
          .find('a')
          .at(3)
          .attr('href'),
      ).toEqual(bojack.website_url); // website

      expect(parentDiv.childAt(3)).toEqual(context.find('div').at(2));
      expect(
        context
          .find('div')
          .at(2)
          .text(),
      ).toEqual(bojack.summary); // user.summary
      expect(
        context
          .find('div')
          .at(6)
          .text(),
      ).toEqual(bojack.location); // user.location
      expect(
        context
          .find('div')
          .at(8)
          .text(),
      ).toEqual(bojack.joined_at); // user.joined_at
    });
  });

  describe('for user mrpeanutbutter', () => {
    it('should render and test snapshot with user mrpeanutbutter', () => {
      const tree = render(getUserDetails(mrpeanutbutter));
      expect(tree).toMatchSnapshot();
    });

    it('should have the appropriate elements, attributes and values for user mr peanutbutter', () => {
      const context = shallow(getUserDetails(mrpeanutbutter));
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
      ).toEqual(mrpeanutbutter.profile_image); // profile pic

      expect(parentDiv.childAt(1)).toEqual(context.find('h1'));
      expect(context.find('h1').text()).toEqual(mrpeanutbutter.name); // user.name
      expect(
        context
          .find('a')
          .at(0)
          .attr('href'),
      ).toEqual(`/${mrpeanutbutter.username}`); // user.username

      // social links
      expect(
        context
          .find('a')
          .at(1)
          .attr('href'),
      ).toEqual(`https://twitter.com/${mrpeanutbutter.twitter_username}`); // twitter
      expect(
        context
          .find('a')
          .at(2)
          .attr('href'),
      ).toEqual(`https://github.com/${mrpeanutbutter.github_username}`); // github
      expect(
        context
          .find('a')
          .at(3)
          .attr('href'),
      ).toEqual(mrpeanutbutter.website_url); // website

      expect(parentDiv.childAt(3)).toEqual(context.find('div').at(2));
      expect(
        context
          .find('div')
          .at(2)
          .text(),
      ).toEqual(mrpeanutbutter.summary); // user.summary
      expect(
        context
          .find('div')
          .at(6)
          .text(),
      ).toEqual(mrpeanutbutter.location); // user.location
      expect(
        context
          .find('div')
          .at(8)
          .text(),
      ).toEqual(mrpeanutbutter.joined_at); // user.joined_at
    });
  });
});
