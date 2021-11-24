import { h } from 'preact';
import {
  render,
  fireEvent,
  waitForElementToBeRemoved,
  createEvent,
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
    const uploadInput = getByLabelText(/Upload image/i);

    expect(uploadInput.getAttribute('type')).toEqual('file');
  });

  describe('when rendered in native iOS with imageUpload_disabled support', () => {
    beforeEach(() => {
      global.Runtime = {
        isNativeIOS: jest.fn((namespace) => {
          return namespace === 'imageUpload_disabled';
        }),
      };
    });

    it('does not display the file input', async () => {
      const { queryByLabelText } = render(<ImageUploader />);
      expect(queryByLabelText(/Upload image/i)).not.toBeInTheDocument();
    });

    it('triggers a webkit messageHandler call when isNativeIOS', async () => {
      global.window.ForemMobile = { injectNativeMessage: jest.fn() };

      const { queryByLabelText } = render(<ImageUploader />);
      const uploadButton = queryByLabelText(/Upload an image/i);
      uploadButton.click();
      expect(
        global.window.ForemMobile.injectNativeMessage,
      ).toHaveBeenCalledTimes(1);
    });

    it('handles a native bridge message correctly', async () => {
      const { container, findByTitle } = render(<ImageUploader />); // eslint-disable-line no-unused-vars

      // Fire a change event in the hidden input with JSON payload for success
      const fakeSuccessMessage = JSON.stringify({
        action: 'success',
        link: '/some-fake-image.jpg',
        namespace: 'imageUpload',
      });
      const event = createEvent(
        'ForemMobile',
        document,
        { detail: fakeSuccessMessage },
        { EventType: 'CustomEvent' },
      );
      fireEvent(document, event);

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

    const inputEl = getByLabelText(/Upload image/i);
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

    const { findByTitle, getByDisplayValue, getByLabelText, queryByText } =
      render(<ImageUploader />);
    const inputEl = getByLabelText(/Upload image/i);

    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });

    fireEvent.change(inputEl, { target: { files: [file] } });
    const uploadingImage = queryByText(/uploading.../i);

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
    const inputEl = getByLabelText(/Upload image/i);

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
