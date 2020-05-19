import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
import { ImageUploader } from '../ImageUploader';

describe('<ImageUploader />', () => {
  it('renders correctly without an image', () => {
    const tree = render(<ImageUploader />);

    expect(tree).toMatchSnapshot();
  });

  xit('displays the correct text to copy based on the image', () => {
    const context = deep(<ImageUploader />);
    expect(context.component()).toBeInstanceOf(ImageUploader);
    context.setState({
      insertionImageUrls: ['/i/jxuopxlscfy6wkfbbkvb.png'],
      uploadError: false,
      uploadErrorMessage: null,
    });
  });
});
