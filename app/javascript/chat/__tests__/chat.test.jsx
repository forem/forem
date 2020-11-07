import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { JSDOM } from 'jsdom';
import { axe } from 'jest-axe';
import Chat from '../chat';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;

// mock observer and user ID
window.IntersectionObserver = jest.fn(function intersectionObserverMock() {
  this.observe = jest.fn();
});
global.window.currentUser = { id: 'some_id' };

function getRootData() {
  return {
    chatChannels: JSON.stringify([
      {
        channel_name: 'channel name 1',
        last_opened_at: 'September 2, 2018',
        channel_users: [],
        last_message_at: 'September 21, 2018',
        channel_type: 'group',
        slug: '0',
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
        id: 34561,
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
        id: 67890,
        messages_count: 56,
      },
    ]),
    chatOptions: JSON.stringify({
      showChannelsList: true,
      showTimestamp: true,
      activeChannelId: 34561,
    }),
    githubToken: 'somegithubtoken',
    pusherKey: 'somepusherkey',
    tagModerator: JSON.stringify({ isTagModerator: true }),
  };
}

function getMockResponse() {
  return JSON.stringify({
    result: [
      {
        id: 117921,
        status: 'active',
        viewable_by: 9597,
        chat_channel_id: 51923,
        last_opened_at: '2020-06-07T15:51:12.033Z',
        channel_text:
          'Tag Moderators tag-moderators Nick Taylor (he/him) Ben Greenberg Jess Lee (she/her) Katie Nelson ☞ Desigan Chinniah ☜',
        channel_last_message_at: '2020-06-07T02:13:01.230Z',
        channel_status: 'active',
        channel_type: 'invite_only',
        channel_username: null,
        channel_name: 'Tag Moderators',
        channel_image:
          'https://practicaldev-herokuapp-com.freetls.fastly.net/assets/organization-d83b2b577749cb1cb5c615003fc0d379f0bacc3be6cc1f541ac5655a9d770855.svg',
        channel_modified_slug: 'tag-moderators',
        channel_discoverable: false,
        channel_messages_count: 3287,
        last_indexed_at: '2020-06-07T15:51:11.100Z',
      },
      {
        id: 209670,
        status: 'active',
        viewable_by: 9597,
        chat_channel_id: 100437,
        last_opened_at: '2020-06-07T16:05:41.636Z',
        channel_text:
          '#react mods react-mods-5en7 Nick Taylor (he/him) Michael Tharrington (he/him) Chris Achard',
        channel_last_message_at: '2020-06-05T17:03:19.872Z',
        channel_status: 'active',
        channel_type: 'invite_only',
        channel_username: null,
        channel_name: '#react mods',
        channel_image:
          'https://practicaldev-herokuapp-com.freetls.fastly.net/assets/organization-d83b2b577749cb1cb5c615003fc0d379f0bacc3be6cc1f541ac5655a9d770855.svg',
        channel_modified_slug: 'react-mods-5en7',
        channel_discoverable: false,
        channel_messages_count: 7,
        last_indexed_at: '2020-06-07T16:05:40.723Z',
      },
      {
        id: 204169,
        status: 'active',
        viewable_by: 9597,
        chat_channel_id: 101735,
        last_opened_at: '2017-01-01T05:00:00.000Z',
        channel_text:
          'Direct  carolskelly  nickytonline carolskelly/nickytonline Nick Taylor (he/him) Carol Skelly',
        channel_last_message_at: '2020-03-28T00:57:52.210Z',
        channel_status: 'active',
        channel_type: 'direct',
        channel_username: 'carolskelly',
        channel_name: '@carolskelly',
        channel_image:
          'https://res.cloudinary.com/practicaldev/image/fetch/s--lQ_RERs9--/c_fill,f_auto,fl_progressive,h_90,q_auto,w_90/https://dev-to-uploads.s3.amazonaws.com/uploads/user/profile_image/11343/jDcwvKh7.jpg',
        channel_modified_slug: '@carolskelly',
        channel_messages_count: 0,
        last_indexed_at: '2020-04-04T00:57:52.331Z',
      },
    ],
  });
}

describe('<Chat />', () => {
  const csrfToken = 'this-is-a-csrf-token';

  beforeAll(() => {
    global.Pusher = jest.fn(() => ({
      subscribe: jest.fn(() => ({
        bind: jest.fn(),
      })),
    }));
    global.fetch = fetch;
    global.getCsrfToken = async () => csrfToken;
  });

  afterAll(() => {
    delete global.Pusher;
    delete global.fetch;
    delete global.getCsrfToken;
  });

  it('should have no a11y violations', async () => {
    fetch.mockResponse(getMockResponse());
    const { container } = render(<Chat {...getRootData()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render expanded', () => {
    fetch.mockResponse(getMockResponse());
    const { getByTestId, getByText, getByRole } = render(
      <Chat {...getRootData()} />,
    );
    const chat = getByTestId('chat');

    expect(chat.getAttribute('aria-expanded')).toEqual('true');

    // chat filtering
    getByText('all', { selector: 'button' });
    getByText('direct', { selector: 'button' });
    getByText('group', { selector: 'button' });

    // renderActiveChatChannel
    const activeChat = getByTestId('active-chat');

    expect(activeChat).not.toBeNull();

    getByText('Scroll to Bottom', { selector: '[type="button"]' });

    // Delete modal should be visible
    getByRole('dialog', {
      selector: '[aria-hidden="false"]',
    });
    getByText('Are you sure, you want to delete this message?');
    getByText('Cancel', { selector: '[type="button"]' });
    getByText('Delete', { selector: '[type="button"]' });
  });

  it('should collapse and expand chat channels properly', async () => {
    fetch.mockResponse(getMockResponse());
    const { queryByText } = render(<Chat {...getRootData()} />);

    // // chat channels
    expect(
      queryByText('all', {
        selector: 'button',
      }),
    ).toBeDefined();
    expect(
      queryByText('direct', {
        selector: 'button',
      }),
    ).toBeDefined();
    expect(
      queryByText('group', {
        selector: 'button',
      }),
    ).toBeDefined();
  });
});
