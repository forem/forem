import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
import { ImageUploader } from '../ImageUploader';

describe('<ImageUploader />', () => {
  it('renders correctly without an image', () => {
    const tree = render(<ImageUploader />);
    expect(tree).toMatchSnapshot();
  });

  it('displays text to copy', () => {
    const context = deep(<ImageUploader />);
    expect(context.component()).toBeInstanceOf(ImageUploader);
    context.setState({
      insertionImageUrls: ['/i/jxuopxlscfy6wkfbbkvb.png'],
      uploadError: false,
      uploadErrorMessage: null,
    });

    expect(context.find('#image-markdown-copy-link-input').exists()).toEqual(
      true,
    );
  });

  it('displays Copied! when clicking on the icon', () => {
    const context = deep(<ImageUploader />);
    expect(context.component()).toBeInstanceOf(ImageUploader);
    context.setState({
      insertionImageUrls: ['/i/jxuopxlscfy6wkfbbkvb.png'],
      uploadError: false,
      uploadErrorMessage: null,
    });

    document.getElementById = jest.fn(() => {
      return {
        value: 'some copied text',
        setSelectionRange: () => {},
      };
    });

    document.execCommand = jest.fn();

    context.find('clipboard-copy').simulate('click');

    expect(context.find('ClipboardButton').attrs().showCopyMessage).toEqual(
      true,
    );
    expect(context.find('#image-markdown-copy-link-announcer').text()).toEqual(
      'Copied!',
    );
  });

  it('displays an error when one occurs', () => {
    const error = 'Some error message';
    const context = shallow(<ImageUploader />);
    expect(context.component()).toBeInstanceOf(ImageUploader);
    context.setState({
      insertionImageUrls: [],
      uploadError: true,
      uploadErrorMessage: error,
    });
    expect(context.find('.color-accent-danger').text()).toEqual(error);
  });
});
