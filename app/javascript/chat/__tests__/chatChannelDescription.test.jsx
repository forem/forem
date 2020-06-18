import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ChannelDescriptionSection from '../ChatChannelSettings/ChannelDescriptionSection';

const data = {
  channelName: "some name",
  channelDescription: "some description",
  currentMembershipRole: "mod"
}

const getChannelDescriptionSection = (channelDetails) => {
  return (
    <ChannelDescriptionSection
      channelName={channelDetails.channelName}
      channelDescription={channelDetails.channelDescription}
      currentMembershipRole={channelDetails.currentMembershipRole} 
    />
  )
}

describe('<ChannelDescriptionSection />', () => {
  it ('should render and test snapshot', () => {
    const tree = render(getChannelDescriptionSection(data));
    
    expect(tree).toMatchSnapshot();
  })

  it ("should render the the component", () => {
    const context = shallow(getChannelDescriptionSection(data));
    
    expect(context.find('.channel_details').exists()).toEqual(true);
  })

  it ("should render the same header", () => {
    const context = shallow(getChannelDescriptionSection(data));
    expect(context.find('.channel_title').text()).toEqual(data.channelName)
  })
})
