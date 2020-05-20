import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import { Close } from '../Close';

describe('<Close />', () => {
  it('renders properly', () => {
    const tree = render(<Close />);
    expect(tree).toMatchSnapshot();
  });

  it('shows the modal', () => {
    const container = shallow(<Close />);
    expect(container.find('.crayons-article-form__close').exists()).toEqual(
      true,
    );
  });
});
