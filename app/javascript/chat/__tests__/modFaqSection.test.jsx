import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ModFaqSection from '../ChatChannelSettings/ModFaqSection';

const data = {
  currentMembershipRole: 'mod',
};

const memberUser = {
  currentMembershipRole: 'member',
};

const getModFaqSection = (resource) => {
  return (
    <ModFaqSection currentMembershipRole={resource.currentMembershipRole} />
  );
};

describe('<ChannelDescriptionSection />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getModFaqSection(data));

    expect(tree).toMatchSnapshot();
  });

  it('should render the the component', () => {
    const context = shallow(getModFaqSection(data));

    expect(context.find('.faq-section').exists()).toEqual(true);
  });

  it('should have the contact details', () => {
    const context = shallow(getModFaqSection(data));

    expect(context.find('.contact-details').exists()).toEqual(true);
  });

  it('should render the same link text', () => {
    const context = shallow(getModFaqSection(data));

    expect(context.find('.url-link').text()).toEqual('yo@dev.to');
  });

  it('should not render the element', () => {
    const context = shallow(getModFaqSection(memberUser));
    expect(context.find('.faq-section').exists()).toEqual(false);
  });
});
