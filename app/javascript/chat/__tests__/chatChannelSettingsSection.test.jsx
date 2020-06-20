import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ChatChannelSettingsSection from '../ChatChannelSettings/ChatChannelSettingsSection';

const propData = {
  channelDiscoverable: true,
  chatChannel: {
    name: 'dummy-channel',
    description: 'dummy-description',
    id: 1,
  },
  currentMembership: {
    role: 'mod',
    user_id: 1,
    chat_channel_id: 1,
    id: 2,
    status: 'active',
  },
  pendingMemberships: [
    {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'member',
      status: 'pending',
      image: '',
    },
  ],
  requestedMemberships: [
    {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'member',
      status: 'requested',
      image: '',
    },
  ],
  activeMemberships: [
    {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'mod',
      status: 'active',
      image: '',
    },
  ],
};

const getChatChannelSettingsSection = (data) => (
  <ChatChannelSettingsSection
    channelDiscoverable={data.channelDiscoverable}
    chatChannel={data.chatChannel}
    currentMembership={data.currentMembership}
    pendingMemberships={data.pendingMemberships}
    requestedMemberships={data.requestedMemberships}
    activeMemberships={data.activeMemberships}
  />
);

describe('<ChatChannelSettingsSection />', () => {
  it('should render & test snapshot', () => {
    const tree = render(getChatChannelSettingsSection(propData));
    expect(tree).toMatchSnapshot();
  });

  it('should have the chat channel description component', () => {
    const context = shallow(getChatChannelSettingsSection(propData));
    expect(context.find('.channel-description-section').exists()).toEqual(true);
  });

  it('shoul render the chat channel membership section', () => {
    const context = shallow(getChatChannelSettingsSection(propData));
    expect(context.find('.channel-membership-sections').exists()).toEqual(true);
  });

  it('shoul render the chat channel mod section', () => {
    const context = shallow(getChatChannelSettingsSection(propData));
    expect(context.find('.channel-mod-section').exists()).toEqual(true);
  });

  it('shoul render the chat channel personal section', () => {
    const context = shallow(getChatChannelSettingsSection(propData));
    expect(context.find('.channel-personal-seeting').exists()).toEqual(true);
  });

  it('shoul render the chat channel leave membership section', () => {
    const context = shallow(getChatChannelSettingsSection(propData));
    expect(context.find('.channel-leave-membership-section').exists()).toEqual(
      true,
    );
  });

  it('shoul render the chat channel mod faq section', () => {
    const context = shallow(getChatChannelSettingsSection(propData));
    expect(context.find('.channel-mod-faq').exists()).toEqual(true);
  });
});
