import { h } from 'preact';
import {
  render,
  fireEvent,
  waitForElementToBeRemoved,
} from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import { ImageUploader } from '../ImageUploader';
import '@testing-library/jest-dom';

global.fetch = fetch;

describe('<ImageUploader />', () => {
  beforeEach(() => {
    global.Runtime = {
      isNativeIOS: jest.fn(() => {
        return false;
      }),
    };
  });

  it('should have no a11y violations', async () => {
    const { container } = render(<ImageUploader />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('displays an upload input', () => {
    const { getByLabelText } = render(<ImageUploader />);
    const uploadInput = getByLabelText(/Upload an image/i);

    expect(uploadInput.getAttribute('type')).toEqual('file');
  });

  describe('when rendered in native iOS with imageUpload support', () => {
    beforeEach(() => {
      global.Runtime = {
        isNativeIOS: jest.fn((namespace) => {
          return namespace === 'imageUpload';
        }),
      };
    });

    it('does not display the file input', async () => {
      const { queryByText } = render(<ImageUploader />);
      expect(queryByText(/Upload an image/i)).not.toBeInTheDocument();
    });

    it('triggers a webkit messageHandler call when isNativeIOS', async () => {
      global.window.webkit = {
        messageHandlers: {
          imageUpload: {
            postMessage: jest.fn(),
          },
        },
      };

      const { queryByLabelText } = render(<ImageUploader />);
      const uploadButton = queryByLabelText(/Upload an image/i);
      uploadButton.click();
      expect(
        window.webkit.messageHandlers.imageUpload.postMessage,
      ).toHaveBeenCalledTimes(1);
    });

    it('handles a native bridge message correctly', async () => {
      const { container, findByTitle } = render(<ImageUploader />);
      const nativeInput = container.querySelector(
        '#native-image-upload-message',
      );

      // Fire a change event in the hidden input with JSON payload for success
      const fakeSuccessMessage = `{ "action": "success", "link": "/some-fake-image.jpg" }`;
      fireEvent.change(nativeInput, { target: { value: fakeSuccessMessage } });

      expect(await findByTitle(/copy markdown for image/i)).toBeDefined();
    });
  });

  it('displays the upload spinner during upload', async () => {
    fetch.mockResponse(
      JSON.stringify({
        links: ['/i/fake-link.jpg'],
      }),
    );

    const { getByLabelText, queryByText } = render(<ImageUploader />);

    const inputEl = getByLabelText(/Upload an image/i);
    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });

    fireEvent.change(inputEl, { target: { files: [file] } });

    const uploadingImage = queryByText(/uploading.../i);

    expect(uploadingImage).toBeDefined();
  });

  it('displays text to copy after upload', async () => {
    fetch.mockResponse(
      JSON.stringify({
        links: ['/i/fake-link.jpg'],
      }),
    );

    const {
      findByTitle,
      getByDisplayValue,
      getByLabelText,
      queryByText,
    } = render(<ImageUploader />);
    const inputEl = getByLabelText(/Upload an image/i);

    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });

    fireEvent.change(inputEl, { target: { files: [file] } });
    let uploadingImage = queryByText(/uploading.../i);

    expect(uploadingImage).toBeDefined();

    expect(inputEl.files[0]).toEqual(file);
    expect(inputEl.files).toHaveLength(1);

    waitForElementToBeRemoved(() => queryByText(/uploading.../i));

    expect(await findByTitle(/copy markdown for image/i)).toBeDefined();

    getByDisplayValue(/fake-link.jpg/i);
  });

  // TODO: 'Copied!' is always in the DOM, and so we cannot test that the visual implications of the copy when clicking on the copy icon

  it('displays an error when one occurs', async () => {
    fetch.mockReject({
      message: 'Some Fake Error',
    });

    const { getByLabelText, findByText, queryByText } = render(
      <ImageUploader />,
    );
    const inputEl = getByLabelText(/Upload an image/i);

    // Check the input validation settings
    expect(inputEl.getAttribute('accept')).toEqual('image/*');
    expect(Number(inputEl.dataset.maxFileSizeMb)).toEqual(25);

    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });

    fireEvent.change(inputEl, {
      target: {
        files: [file],
      },
    });

    expect(await findByText(/uploading.../i)).not.toBeNull();

    // Upload is finished, so the messsage has disappeared.
    expect(queryByText(/uploading.../i)).toBeNull();

    await findByText(/some fake error/i);
  });
});
