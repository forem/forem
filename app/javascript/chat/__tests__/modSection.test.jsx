import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ModSection from '../ChatChannelSettings/ModSection';

const data = {
  currentMembershipRole: 'mod',
};

const getModSection = (resource) => {
  return <ModSection currentMembershipRole={resource.currentMembershipRole} />;
};

describe('<ModSection />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getModSection(data));

    expect(tree).toMatchSnapshot();
  });

  it('should render the the component', () => {
    const context = shallow(getModSection(data));

    expect(context.find('.mod-section').exists()).toEqual(true);
  });
});
