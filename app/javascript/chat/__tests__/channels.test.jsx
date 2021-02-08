import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { JSDOM } from 'jsdom';
import { axe } from 'jest-axe';
import { Channels } from '../channels';

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
    status: 'active',
    messages_count: 124,
  },
  {
    channel_name: 'group channel 2',
    status: 'active',
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
    status: 'active',
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
    it('should have no a11y violations', async () => {
      const { container } = render(getChannels(true, fakeChannels));
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('should render with chat channels', () => {
      const { getByText, getByRole, queryByRole } = render(
        getChannels(true, fakeChannels),
      );

      // welcome message should not exist because there are channels
      expect(queryByRole('alert')).toBeNull();

      // configFooter should exist
      fireEvent.click(
        getByRole('button', { name: /configuration navigation menu/i }),
      );
      const settings = getByText('Settings');
      expect(settings.getAttribute('href')).toEqual('/settings');

      const reportAbuse = getByText('Report Abuse');
      expect(reportAbuse.getAttribute('href')).toEqual('/report-abuse');
    });

    it('should render without chat channels', () => {
      const { getByText, getByRole } = render(getChannels(true, []));

      // should show "Welcome to Connect message....."
      getByRole('alert');

      fireEvent.click(
        getByRole('button', { name: /configuration navigation menu/i }),
      );
      const settings = getByText('Settings');
      expect(settings.getAttribute('href')).toEqual('/settings');

      const reportAbuse = getByText('Report Abuse');
      expect(reportAbuse.getAttribute('href')).toEqual('/report-abuse');
    });
  });

  describe('not expanded', () => {
    it('should have no a11y violations', async () => {
      const { container } = render(getChannels(false, fakeChannels));
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('should have the proper elements, attributes, and content', () => {
      const { queryByTestId } = render(getChannels(false, fakeChannels));

      // should have group names but no user names
      // TODO: I don't understand the comment above. To revisit.
      expect(queryByTestId('chat-channels-list')).toBeDefined();
    });
  });

  describe('without chat channels', () => {
    it('should have no a11y violations', async () => {
      const { container } = render(getChannels(false, []));
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('should render without chat channels', () => {
      const { getByTestId } = render(getChannels(false, []));

      // should have nothing but empty str
      const chatChannelList = getByTestId('chat-channels-list');

      expect(chatChannelList.textContent).toEqual('');
    });
  });
});
