import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { Tabs } from '../Tabs';

describe('<Tabs />', () => {
  it('renders properly', () => {
    const tree = render(<Tabs onPreview={null} previewShowing={false} />);
    expect(tree).toMatchSnapshot();
  });

  it('highlights the current tab', () => {
    const container1 = shallow(<Tabs onPreview={null} previewShowing />);
    expect(container1.find('.crayons-tabs__item--current').text()).toEqual(
      'Preview',
    );

    const container2 = shallow(
      <Tabs onPreview={null} previewShowing={false} />,
    );
    expect(container2.find('.crayons-tabs__item--current').text()).toEqual(
      'Edit',
    );
  });
});
