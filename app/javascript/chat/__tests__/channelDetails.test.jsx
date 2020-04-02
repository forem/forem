import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import fetch from 'jest-fetch-mock';
import ChannelDetails from '../channelDetails';

global.fetch = fetch;
const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;
global.window.currentUser = { id: 'modID' };

const channelDetails = mod => {
  let id;
  if (mod) {
    id = 'modID';
  } else {
    id = 'userID';
  }
  return {
    channel_name: 'channel name',
    description: 'something about this channel',
    id: '12345',
    channel_users: [
      {
        path: '/user_path1',
        title: 'i am channel user 1',
        name: 'channel user 1',
        username: 'channeluser1',
        id: 'userid1',
        profile_image_url: 'channeluser1pic.png',
      },
      {
        path: '/user_path2',
        title: 'i am channel user 2',
        name: 'channel user 2',
        username: 'channeluser2',
        id: 'userid2',
        profile_image_url: 'channeluser2pic.png',
      },
    ],
    type_of: 'channel-details',
    pending_users_select_fields: [
      {
        path: '/pending_path1',
        title: 'i am pending user 1',
        name: 'pending user 1',
        username: 'pendinguser1',
        id: 'pendinguserid1',
        profile_image_url: 'pendinguser1pic.png',
      },
      {
        path: '/pending_path2',
        title: 'i am pending user 2',
        name: 'pending user 2',
        username: 'pendinguser2',
        id: 'pendinguserid2',
        profile_image_url: 'pendinguser2pic.png',
      },
    ],
    channel_mod_ids: id,
  };
};

const getChannelDetails = details => (
  <ChannelDetails channel={details} activeChannelId={12345} />
);

describe('<ChannelDetails />', () => {
  describe('as a moderator', () => {
    const moddetails = channelDetails(true);
    const context = shallow(getChannelDetails(moddetails));

    it('should render and test snapshot', () => {
      const tree = render(getChannelDetails(moddetails));
      expect(tree).toMatchSnapshot();
    });

    it('should have the proper elements, attributes and content', () => {
      expect(context.find('.channeldetails').exists()).toEqual(true);
      expect(context.find('.channeldetails__name').text()).toEqual(
        moddetails.channel_name,
      );
      expect(context.find('.channeldetails__description').text()).toEqual(
        moddetails.description,
      );

      // check user members
      const channelmembers = context.find('.channeldetails__user');
      expect(channelmembers.exists()).toEqual(true);
      for (let i = 0; i < channelmembers.length; i += 1) {
        expect(channelmembers.at(i).text()).toEqual(
          moddetails.channel_users[i].name,
        );
        expect(
          channelmembers
            .at(i)
            .childAt(1)
            .attr('href'),
        ).toEqual(`/${moddetails.channel_users[i].username}`);
        expect(
          channelmembers
            .at(i)
            .childAt(1)
            .attr('data-content'),
        ).toEqual(`sidecar-user`);
      }

      // mod only divs
      expect(context.find('.channeldetails__searchedusers').exists()).toEqual(
        false,
      ); // no searched users
      expect(context.find('.channeldetails__pendingusers').exists()).toEqual(
        true,
      );
      expect(context.find('.channeldetails__inviteusers').exists()).toEqual(
        true,
      );
      expect(context.find('.channeldetails__leftchannel').exists()).toEqual(
        false,
      );
      expect(context.find('.channeldetails__leavechannel').exists()).toEqual(
        false,
      );

      // check pending members
      const pendingusers = context.find('.channeldetails__pendingusers');
      for (let i = 0; i < pendingusers.length; i += 1) {
        expect(pendingusers.at(i).text()).toEqual(
          `@${moddetails.pending_users_select_fields[i].username} - ${moddetails.pending_users_select_fields[i].name}`,
        );
        expect(
          pendingusers
            .at(i)
            .childAt(0)
            .attr('href'),
        ).toEqual(`/${moddetails.pending_users_select_fields[i].username}`);
        expect(
          pendingusers
            .at(i)
            .childAt(0)
            .attr('data-content'),
        ).toEqual(`users/${moddetails.pending_users_select_fields[i].id}`);
      }
    });

    it('should search users and populate searched users div', async () => {
      // context.component().triggerUserSearch({ target: { value: 'ma', selectionStart: 2 } })
      const searchedusers = {
        searchedUsers: [
          {
            path: '/user_path1',
            title: 'i am channel user 1',
            user: {
              name: 'channel user 1',
              username: 'channeluser1',
              profile_image_90: 'channeluser1pic.png',
            },
            id: 'userid1',
          },
          {
            path: '/pending_path1',
            title: 'i am pending user 1',
            user: {
              name: 'pending user 1',
              username: 'pendinguser1',
              profile_image_90: 'pendinguser1pic.png',
            },
            id: 'pendinguserid1',
          },
          {
            path: '/search_path3',
            title: 'i am searched user 3',
            user: {
              name: 'searched user 3',
              username: 'searcheduser3',
              profile_image_90: 'searcheduser3pic.png',
            },
            id: 'searched_userid3',
          },
        ],
      };

      context.setState(searchedusers);
      context.rerender();
      const searchedusersdivs = context.find('.channeldetails__searchedusers');
      expect(searchedusersdivs.exists()).toEqual(true);
      expect(searchedusersdivs.length).toEqual(2);

      let inviteMessage;
      let inviteAttr;
      let inviteAttrAns;
      const included = (list, el) => {
        const keys = Object.keys(list);
        for (let i = 0; i < keys.length; i += 1) {
          const key = keys[i];
          if (list[key].id === el.id) {
            return true;
          }
        }
        return false;
      };
      for (let i = 0; i < searchedusersdivs.length; i += 1) {
        if (
          !included(
            moddetails.pending_users_select_fields,
            searchedusers.searchedUsers[i],
          )
        ) {
          expect(
            searchedusersdivs
              .at(i)
              .childAt(0)
              .attr('href'),
          ).toEqual(searchedusers.searchedUsers[i].path);
          expect(
            searchedusersdivs
              .at(i)
              .childAt(0)
              .text(),
          ).toEqual(
            `@${searchedusers.searchedUsers[i].user.username} - ${searchedusers.searchedUsers[i].title}`,
          );

          if (
            included(moddetails.channel_users, searchedusers.searchedUsers[i])
          ) {
            inviteMessage = `is already in ${moddetails.channel_name}`;
            inviteAttr = 'className';
            inviteAttrAns = 'channel__member';
          } else {
            inviteMessage = 'Invite';
            inviteAttr = 'data-content';
            inviteAttrAns = searchedusers.searchedUsers[i].id;
          }
          expect(
            searchedusersdivs
              .at(i)
              .childAt(2)
              .text(),
          ).toEqual(inviteMessage);
          expect(
            searchedusersdivs
              .at(i)
              .childAt(2)
              .attr(inviteAttr),
          ).toEqual(inviteAttrAns);
        }
      }
      const tree = render(context);
      expect(tree).toMatchSnapshot();
    });
  });

  describe('as a user', () => {
    const userdetails = channelDetails(false);
    const context = shallow(getChannelDetails(userdetails));

    it('should render and test snapshot', () => {
      const tree = render(getChannelDetails(userdetails));
      expect(tree).toMatchSnapshot();
    });

    it('should have the proper elements, attributes and content', () => {
      expect(context.find('.channeldetails').exists()).toEqual(true);
      expect(context.find('.channeldetails__name').text()).toEqual(
        userdetails.channel_name,
      );
      expect(context.find('.channeldetails__description').text()).toEqual(
        userdetails.description,
      );

      const channelmembers = context.find('.channeldetails__user');
      expect(channelmembers.exists()).toEqual(true);
      for (let i = 0; i < channelmembers.length; i += 1) {
        expect(channelmembers.at(i).text()).toEqual(
          userdetails.channel_users[i].name,
        );
        expect(
          channelmembers
            .at(i)
            .childAt(1)
            .attr('href'),
        ).toEqual(`/${userdetails.channel_users[i].username}`);
        expect(
          channelmembers
            .at(i)
            .childAt(1)
            .attr('data-content'),
        ).toEqual(`sidecar-user`);
      }

      // user only divs
      expect(context.find('.channeldetails__searchedusers').exists()).toEqual(
        false,
      );
      expect(context.find('.channeldetails__pendingusers').exists()).toEqual(
        false,
      );
      expect(context.find('.channeldetails__inviteusers').exists()).toEqual(
        false,
      );
      expect(context.find('.channeldetails__leftchannel').exists()).toEqual(
        false,
      );
      expect(context.find('.channeldetails__leavechannel').exists()).toEqual(
        true,
      );
    });

    it('should leave channel and show appropriate message', () => {
      // leave channel
      context.component().handleLeaveChannelSuccess();
      context.rerender();
      expect(context.find('.channeldetails__leftchannel').exists()).toEqual(
        true,
      );
      expect(context.find('.channeldetails__leavechannel').exists()).toEqual(
        false,
      );

      const tree = render(context);
      expect(tree).toMatchSnapshot();
    });
  });
});
