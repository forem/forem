import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ModSection from '../ChatChannelSettings/ModSection';

const modUser = {
  currentMembershipRole: 'mod',
};

const memberUser = {
  currentMembershipRole: 'member',
};

const getModSection = (resource) => {
  return <ModSection currentMembershipRole={resource.currentMembershipRole} />;
};

describe('<ModSection />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getModSection(modUser));

    expect(tree).toMatchSnapshot();
  });

  it('should render the the component', () => {
    const context = shallow(getModSection(modUser));

    expect(context.find('.mod-section').exists()).toEqual(true);
  });

  it('should not render the the component', () => {
    const context = shallow(getModSection(memberUser));

    expect(context.find('.mod-section').exists()).toEqual(false);
  });
});
