import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import { JSDOM } from 'jsdom';
import Chat from '../chat';

global.fetch = fetch;

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.document.body.innerHTML =
  '<div class="chat chat--expanded" data-no-instant={true}><div class="chat__activechat"><div class="activechatchannel"><div class="activechatchannel__conversation"><div class="activechatchannel__header"></div><div class="activechatchannel__messages" id="messagelist"><div class="messagelist__sentinel" id="messagelist__sentinel"/></div><div class="activechatchannel__alerts"><div class="chatalert__default chatalert__default--hidden">More new messages below</div></div><div class="activechatchannel__form"><div class="messagecomposer"><textarea class="messagecomposer__input" id="messageform" maxLength="1000" onKeyDown={[Function]} placeholder="Message goes here" /><button class="messagecomposer__submit" onClick={[Function]}>SEND</button></div></div></div></div></div></div>';
global.window = doc.defaultView;

// mock observer and user ID
window.IntersectionObserver = jest.fn(function intersectionObserverMock() {
  this.observe = jest.fn();
});
global.window.currentUser = { id: 'some_id' };

// fake props to pass to Chat
const rootData = {
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
};

const getChat = () => <Chat {...rootData} />;

describe('<Chat />', () => {
  it('should load chat', () => {
    const tree = render(getChat());
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper elements, attributes and content', () => {
    const context = shallow(getChat());
    expect(context.exists()).toEqual(true);

    expect(context.find('.chat').exists()).toEqual(true);
    expect(context.find('.chat--expanded').exists()).toEqual(true);
    expect(context.find('.chat__activechat').exists()).toEqual(true);

    // renderChatChannels
    expect(context.find('.chat__channels').exists()).toEqual(true);
    expect(context.find('.chat__channelstogglebutt').exists()).toEqual(true);
    expect(context.find('.chat__channeltypefilter').exists()).toEqual(true);
    expect(context.find('.chat__channeltypefilter').text()).toEqual(
      'alldirectgroup',
    );

    // renderActiveChatChannel
    expect(context.find('.activechatchannel').exists()).toEqual(true);
    expect(context.find('.activechatchannel__conversation').exists()).toEqual(
      true,
    );
    expect(context.find('.activechatchannel__header').exists()).toEqual(true);
    expect(context.find('.activechatchannel__messages').exists()).toEqual(true);
    expect(context.find('.activechatchannel__alerts').exists()).toEqual(true); // div that wraps Alert
    expect(context.find('.activechatchannel__form').exists()).toEqual(true); // div that wraps Compose
  });

  it('should un-expand and expand chat channels properly', () => {
    const context = shallow(getChat());

    // un-expand chat channels
    context.find('.chat__channelstogglebutt').simulate('click');
    expect(context.find('.chat__channeltypefilter').exists()).toEqual(false); // now hidden
    expect(context.find('.chat__channeltypefilter').text()).toEqual(''); // no text

    // re-expand chat channel
    context.find('.chat__channelstogglebutt').simulate('click');
    expect(context.find('.chat__channeltypefilter').exists()).toEqual(true);
    expect(context.find('.chat__channeltypefilter').text()).toEqual(
      'alldirectgroup',
    );
  });
});
