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

  // TODO: how to test a closed modal
  // it('closes the modal', () => {
  //   const container = shallow(<Close />);
  //   const closeBtn = container.find('.crayons-article-form__close a');
  //   closeBtn.simulate('click');
  //   expect(container.find('.crayons-article-form__close').exists()).toEqual(false);
  // });
});
