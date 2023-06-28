import { h } from 'preact';
import {
  render,
  fireEvent,
  waitForElementToBeRemoved,
  waitFor,
  createEvent,
} from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import { ImageUploader } from '../ImageUploader';
import '@testing-library/jest-dom';

global.fetch = fetch;

const windowNavigator = window.navigator;
const windowWebkit = window.webkit;

const stubNativeIOSCapabilities = () => {
  Object.defineProperty(window, 'navigator', {
    value: { userAgent: 'DEV-Native-ios|ForemWebView' },
    writable: true,
  });

  Object.defineProperty(window, 'webkit', {
    value: { messageHandlers: { imageUpload: true } },
    writable: true,
  });
};

const resetNativeIOSCapabilities = () => {
  Object.defineProperty(window, 'navigator', {
    value: windowNavigator,
    writable: true,
  });

  Object.defineProperty(window, 'webkit', {
    value: windowWebkit,
    writable: true,
  });
};

describe('<ImageUploader />', () => {
  describe('Editor v1, not native iOS', () => {
    it('should have no a11y violations', async () => {
      const { container } = render(<ImageUploader editorVersion="v1" />);
      const results = await axe(container);
      expect(results).toHaveNoViolations();
    });

    it('displays an upload input', () => {
      const { getByLabelText } = render(<ImageUploader editorVersion="v1" />);
      const uploadInput = getByLabelText(/Upload image/i);

      expect(uploadInput.getAttribute('type')).toEqual('file');
    });

    it('displays the upload spinner during upload', async () => {
      fetch.mockResponse(
        JSON.stringify({
          links: ['/i/fake-link.jpg'],
        }),
      );

      const { getByLabelText, getByText } = render(
        <ImageUploader editorVersion="v1" />,
      );

      const inputEl = getByLabelText(/Upload image/i);
      const file = new File(['(⌐□_□)'], 'chucknorris.png', {
        type: 'image/png',
      });

      fireEvent.change(inputEl, { target: { files: [file] } });

      const uploadingImage = getByText(/uploading.../i);

      expect(uploadingImage).toBeInTheDocument();
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
        getByText,
      } = render(<ImageUploader editorVersion="v1" />);
      const inputEl = getByLabelText(/Upload image/i);

      const file = new File(['(⌐□_□)'], 'chucknorris.png', {
        type: 'image/png',
      });

      fireEvent.change(inputEl, { target: { files: [file] } });
      const uploadingImage = getByText(/uploading.../i);

      expect(uploadingImage).toBeInTheDocument();

      expect(inputEl.files[0]).toEqual(file);
      expect(inputEl.files).toHaveLength(1);

      waitForElementToBeRemoved(() => queryByText(/uploading.../i));

      expect(await findByTitle(/Copy/i)).toBeInTheDocument();

      expect(getByDisplayValue(/fake-link.jpg/i)).toBeInTheDocument();
    });

    // TODO: 'Copied!' is always in the DOM, and so we cannot test that the visual implications of the copy when clicking on the copy icon

    it('displays an error when one occurs', async () => {
      fetch.mockReject({
        message: 'Some Fake Error',
      });

      const { getByLabelText, findByText, queryByText, getByText } = render(
        <ImageUploader editorVersion="v1" />,
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

      // Upload is finished, so the message has disappeared.
      await waitForElementToBeRemoved(() => getByText(/uploading.../i));
      expect(queryByText(/uploading.../i)).not.toBeInTheDocument();

      const errorMsg = await findByText(/some fake error/i);
      expect(errorMsg).toBeInTheDocument();
    });
  });

  describe('Editor v1, native iOS with imageUpload support', () => {
    beforeAll(() => {
      stubNativeIOSCapabilities();
    });

    afterAll(() => {
      resetNativeIOSCapabilities();
    });
    it('does not display the file input', async () => {
      const { queryByLabelText } = render(<ImageUploader editorVersion="v1" />);
      expect(queryByLabelText(/Upload image/i)).not.toBeInTheDocument();
    });

    it('triggers a webkit messageHandler call when isNativeIOS', async () => {
      global.window.ForemMobile = { injectNativeMessage: jest.fn() };

      const { queryByLabelText } = render(<ImageUploader editorVersion="v1" />);
      const uploadButton = queryByLabelText(/Upload an image/i);
      uploadButton.click();
      expect(
        global.window.ForemMobile.injectNativeMessage,
      ).toHaveBeenCalledTimes(1);
    });

    it('handles a native bridge message correctly', async () => {
      const { findByTitle } = render(<ImageUploader editorVersion="v1" />);

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

      expect(await findByTitle(/Copy/i)).toBeInTheDocument();
    });
  });

  describe('Editor v2, not native iOS', () => {
    it('should have no a11y violations', async () => {
      const { container } = render(<ImageUploader editorVersion="v2" />);
      const results = await axe(container);
      expect(results).toHaveNoViolations();
    });

    it('displays an upload image button with input', () => {
      const { getAllByLabelText } = render(
        <ImageUploader editorVersion="v2" />,
      );
      const uploadControls = getAllByLabelText('Upload image');

      expect(uploadControls.length).toEqual(2);
      expect(uploadControls[0].getAttribute('type')).toEqual('file');
    });

    it('displays cancel upload tooltip during upload', () => {
      fetch.mockResponse(
        JSON.stringify({
          links: ['/i/fake-link.jpg'],
        }),
      );

      const { getAllByLabelText, queryByText, getByRole } = render(
        <ImageUploader editorVersion="v2" />,
      );

      expect(queryByText('Cancel upload')).not.toBeInTheDocument();

      const inputEl = getAllByLabelText(/Upload image/i)[0];
      const file = new File(['(⌐□_□)'], 'chucknorris.png', {
        type: 'image/png',
      });

      fireEvent.change(inputEl, { target: { files: [file] } });

      expect(
        getByRole('button', { name: /Cancel image upload/i }),
      ).toBeInTheDocument();
    });

    it('invokes upload start and success callbacks when image is uploaded', async () => {
      fetch.mockResponse(
        JSON.stringify({
          links: ['/i/fake-link.jpg'],
        }),
      );

      const uploadStartCallback = jest.fn();
      const uploadSuccessCallback = jest.fn();

      const { getAllByLabelText, queryByRole, getByRole } = render(
        <ImageUploader
          editorVersion="v2"
          onImageUploadStart={uploadStartCallback}
          onImageUploadSuccess={uploadSuccessCallback}
        />,
      );
      const inputEl = getAllByLabelText(/Upload image/i)[0];

      const file = new File(['(⌐□_□)'], 'chucknorris.png', {
        type: 'image/png',
      });

      fireEvent.change(inputEl, { target: { files: [file] } });

      expect(uploadStartCallback).toHaveBeenCalled();

      await waitForElementToBeRemoved(() =>
        getByRole('button', { name: /Cancel image upload/i }),
      );
      expect(
        queryByRole('button', { name: /Cancel image upload/i }),
      ).not.toBeInTheDocument();

      expect(uploadSuccessCallback).toHaveBeenCalledWith(
        '![Image description](/i/fake-link.jpg)',
      );
    });

    it('invokes error callback when error occurs', async () => {
      fetch.mockReject({
        message: 'Some Fake Error',
      });

      const uploadErrorCallback = jest.fn();

      const { getAllByLabelText, getByRole, queryByRole } = render(
        <ImageUploader
          editorVersion="v2"
          onImageUploadError={uploadErrorCallback}
        />,
      );
      const inputEl = getAllByLabelText(/Upload image/i)[0];

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

      await waitForElementToBeRemoved(() =>
        getByRole('button', { name: /Cancel image upload/i }),
      );
      expect(
        queryByRole('button', { name: /Cancel image upload/i }),
      ).not.toBeInTheDocument();

      expect(uploadErrorCallback).toHaveBeenCalled();
    });
  });

  describe('Editor v2, native iOS with imageUpload support', () => {
    beforeAll(() => {
      stubNativeIOSCapabilities();
    });

    afterAll(() => {
      resetNativeIOSCapabilities();
    });

    it('triggers a webkit messageHandler call when isNativeIOS', async () => {
      global.window.ForemMobile = { injectNativeMessage: jest.fn() };

      const { getByRole } = render(<ImageUploader editorVersion="v2" />);
      const uploadButton = getByRole('button', { name: /Upload image/i });
      uploadButton.click();

      await waitFor(() =>
        expect(
          global.window.ForemMobile.injectNativeMessage,
        ).toHaveBeenCalledTimes(1),
      );
    });

    it('handles a native bridge message correctly', async () => {
      const uploadSuccess = jest.fn();

      render(
        <ImageUploader
          editorVersion="v2"
          onImageUploadSuccess={uploadSuccess}
        />,
      );

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

      await waitFor(() =>
        expect(uploadSuccess).toHaveBeenCalledWith(
          '![Image description](/some-fake-image.jpg)',
        ),
      );
    });
  });
});
