import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import InvitationLinkManager from '../ChatChannelSettings/MembershipManager/InvitationLinkManager';

const data = {
  invitationLink: 'https://dummy.com',
  currentMembership: {
    role: 'mod',
    user_id: 1,
    chat_channel_id: 1,
    id: 2,
    status: 'active',
  },
};

const nonModData = {
  invitationLink: 'https://dummy.com',
  currentMembership: {
    role: 'member',
    user_id: 1,
    chat_channel_id: 1,
    id: 2,
    status: 'active',
  },
};

const getInvitationLinkManager = (resource) => (
  <InvitationLinkManager
    activeMemberships={resource.activeMemberships}
    currentMembership={resource.currentMembership}
  />
);

describe('<getInvitationLinkManager />', () => {
  it('should render the test snapshot', () => {
    const tree = render(getInvitationLinkManager(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the elements', () => {
    const context = shallow(getInvitationLinkManager(data));

    expect(context.find('.invitation-section').exists()).toEqual(true);
  });

  it('should have the title elements', () => {
    const context = shallow(getInvitationLinkManager(data));

    expect(context.find('.title').exists()).toEqual(true);
  });

  it('should not render elements when user have role member', () => {
    const context = shallow(getInvitationLinkManager(nonModData));

    expect(context.find('.invitation-section').exists()).toEqual(false);
  });

  it('should have the button elements', () => {
    const context = shallow(getInvitationLinkManager(data));

    expect(context.find('.spec__image-markdown-copy').exists()).toEqual(true);
  });

  it('should click on the button', () => {
    const context = shallow(getInvitationLinkManager(data));
    context.find('.spec__image-markdown-copy').simulate('click');
    expect(context.find('#image-markdown-copy-link-announcer').text()).toEqual(
      'Copied!',
    );
  });
});
