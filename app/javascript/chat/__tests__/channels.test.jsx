import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import Channels from '../channels';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;
global.window.currentUser = { id: 'fake_username' };

let channelSwitched = false;

const fakeSwitchChannel = () => {
  channelSwitched = !channelSwitched;
};

const fakeChannels = [
  {
    channel_name: 'channel name 1',
    last_opened_at: 'September 2, 2018',
    channel_users: [],
    last_message_at: 'September 21, 2018',
    channel_type: 'group',
    slug: '0',
    channel_modified_slug: '@0',
    id: 12345,
    messages_count: 124,
  },
  {
    channel_name: 'group channel 2',
    last_opened_at: 'September 12, 2018',
    channel_users: [
      {
        profile_image: 'fake_profile_image',
        darker_color: '#111111',
        last_opened_at: 'some last open date',
      },
      {
        profile_image: 'fake_profile_pic',
        darker_color: '#222222',
        last_opened_at: 'some other last open date',
      },
    ],
    last_message_at: 'September 14, 2018',
    channel_type: 'direct',
    slug: '1',
    channel_modified_slug: '@1',
    id: 12345,
    messages_count: 83,
  },
  {
    channel_name: 'group channel 3',
    last_opened_at: 'September 30, 2018',
    channel_users: [
      {
        profile_image: 'fake_profile_image',
        darker_color: '#111111',
        last_opened_at: 'some last open date',
      },
      {
        profile_image: 'fake_profile_pic',
        darker_color: '#222222',
        last_opened_at: 'some other last open date',
      },
    ],
    last_message_at: 'September 29, 2018',
    channel_type: 'group',
    slug: '2',
    channel_modified_slug: '@2',
    id: 67890,
    messages_count: 56,
  },
];

const getChannels = (mod, chatChannels) => (
  <Channels
    incomingVideoCallChannelIds={[]} // no incoming calls
    activeChannelId={12345}
    chatChannels={chatChannels}
    unopenedChannelIds={[]}
    handleSwitchChannel={fakeSwitchChannel}
    channelsLoaded
    filterQuery=""
    expanded={mod}
  />
);

describe('<Channels />', () => {
  describe('expanded', () => {
    describe('with chat channels', () => {
      it('should render and test snapshot', () => {
        const tree = render(getChannels(true, fakeChannels));
        expect(tree).toMatchSnapshot();
      });

      it('should have the proper elements, attributes, and content', () => {
        const context = shallow(getChannels(true, fakeChannels));

        // configFooter should exist
        expect(context.find('.chatchannels__config').exists()).toEqual(true);
        expect(context.find('.chatchannels__configmenu').exists()).toEqual(
          true,
        );
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(0)
            .text(),
        ).toEqual('DEV Settings');
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(0)
            .attr('href'),
        ).toEqual('/settings');
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(1)
            .text(),
        ).toEqual('Report Abuse');
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(1)
            .attr('href'),
        ).toEqual('/report-abuse');

        // welcome message should not exist because there are channels
        expect(
          context.find('.chatchannels__channelslistheader').exists(),
        ).toEqual(false);
      });
    });

    describe('without chat channels', () => {
      it('should render and test snapshot', () => {
        const tree = render(getChannels(true, []));
        expect(tree).toMatchSnapshot();
      });

      it('should have the proper elements, attributes, and content', () => {
        const context = shallow(getChannels(true, []));

        // should show "Welcome to DEV Connect message....."
        expect(
          context.find('.chatchannels__channelslistheader').exists(),
        ).toEqual(true);
        expect(
          context.find('.chatchannels__channelslistheader').text(),
        ).toEqual(
          '👋 Welcome to DEV Connect! You may message anyone you mutually follow.',
        );

        expect(context.find('.chatchannels__config').exists()).toEqual(true);
        expect(context.find('.chatchannels__configmenu').exists()).toEqual(
          true,
        );
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(0)
            .text(),
        ).toEqual('DEV Settings');
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(0)
            .attr('href'),
        ).toEqual('/settings');
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(1)
            .text(),
        ).toEqual('Report Abuse');
        expect(
          context
            .find('.chatchannels__configmenu')
            .childAt(1)
            .attr('href'),
        ).toEqual('/report-abuse');
      });
    });
  });

  describe('not expanded', () => {
    describe('with chat channels', () => {
      it('should render and test snapshot', () => {
        const tree = render(getChannels(false, fakeChannels));
        expect(tree).toMatchSnapshot();
      });

      it('should have the proper elements, attributes, and content', () => {
        const context = shallow(getChannels(false, fakeChannels));

        // should have group names but no user names
        expect(context.find('.chatchannels__channelslist').exists()).toEqual(
          true,
        );
        expect(
          context
            .find('.chatchannels__channelslist')
            .childAt(2)
            .attr('data-channel-slug'),
        ).toEqual('@1'); // check user
        expect(
          context
            .find('.chatchannels__channelslist')
            .childAt(2)
            .text(),
        ).toEqual('group channel 2'); // ensure user has no text
        expect(
          context
            .find('.chatchannels__channelslist')
            .childAt(1)
            .text(),
        ).toEqual(fakeChannels[0].channel_name);
        expect(
          context
            .find('.chatchannels__channelslist')
            .childAt(3)
            .text(),
        ).toEqual(fakeChannels[2].channel_name);
      });
    });

    describe('without chat channels', () => {
      it('should render and test snapshot', () => {
        const tree = render(getChannels(false, []));
        expect(tree).toMatchSnapshot();
      });

      it('should have the proper elements, attributes, and content', () => {
        const context = shallow(getChannels(false, []));

        // should have nothing but empty str
        expect(context.find('.chatchannels__channelslist').exists()).toEqual(
          true,
        );
        expect(context.find('.chatchannels__channelslist').text()).toEqual('');
        expect(
          context.find('.chatchannels__channelslist').children().length,
        ).toEqual(1);
        expect(
          context.find('.chatchannels__channelslist').children()[0],
        ).toEqual(''); // empty child
      });
    });
  });
});
