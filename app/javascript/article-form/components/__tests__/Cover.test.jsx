import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep, shallow } from 'preact-render-spy';
import { Cover } from '../Cover';

describe('<Cover />', () => {
  it('renders properly', () => {
    const tree = render(
      <Cover
        mainImage="/i/r5tvutqpl7th0qhzcw7f.png"
        onMainImageUrlChange={null}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('shows the correct view when there is an image uploaded', () => {
    const container = shallow(
      <Cover
        mainImage="/i/r5tvutqpl7th0qhzcw7f.png"
        onMainImageUrlChange={null}
      />,
    );
    expect(
      container.find('.crayons-article-form__cover__image').exists(),
    ).toEqual(true);
    expect(container.find('.crayons-article-form__cover').text()).toEqual(
      'ChangeRemove',
    );
    expect(container.find('.articleform__uploaderror').exists()).toEqual(false);
  });

  it('shows the correct view when there is no image uploaded', () => {
    const container = shallow(
      <Cover mainImage={null} onMainImageUrlChange={null} />,
    );
    expect(
      container.find('.crayons-article-form__cover__image').exists(),
    ).toEqual(false);
    expect(container.find('.crayons-article-form__cover').text()).toEqual(
      'Add a cover',
    );
  });

  it('displays an upload error when necessary', () => {
    const context = shallow(
      <Cover mainImage={null} onMainImageUrlChange={null} />,
    );
    expect(context.component()).toBeInstanceOf(Cover);
    context.setState({
      uploadError: true,
      uploadErrorMessage: 'Some error message',
    });

    expect(context.find('.articleform__uploaderror').exists()).toEqual(true);
    expect(context.find('.articleform__uploaderror').text()).toEqual(
      'Some error message',
    );
  });

  it('should trigger onMainImageUrlChange when the Remove button is pressed', ()=> {
    const onMainImageUrlChange = jest.fn();

    const context = deep(<Cover
      mainImage="/i/r5tvutqpl7th0qhzcw7f.png"
      onMainImageUrlChange={onMainImageUrlChange}
    />);

    context.find('.crayons-btn--ghost-danger').simulate('click', {
      preventDefault: () => {}
    });
    expect(onMainImageUrlChange).toHaveBeenCalled();
  });


});
