import { h } from 'preact';
import {
  render,
  fireEvent,
  waitForElementToBeRemoved,
  createEvent,
} from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { ArticleCoverImage } from '../ArticleCoverImage';

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

describe('<ArticleCoverImage />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <ArticleCoverImage
        mainImage="/i/r5tvutqpl7th0qhzcw7f.png"
        onMainImageUrlChange={jest.fn()}
      />,
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('displays an upload input when there is no main image', () => {
    const { getByLabelText } = render(
      <ArticleCoverImage mainImage="" onMainImageUrlChange={jest.fn()} />,
    );
    const uploadInput = getByLabelText(/add a cover image/i);
    expect(uploadInput.getAttribute('type')).toEqual('file');
  });

  describe('when an image is uploaded', () => {
    it('shows the uploaded image', () => {
      const { getByRole } = render(
        <ArticleCoverImage
          mainImage="/some-fake-image.jpg"
          onMainImageUrlChange={jest.fn()}
        />,
      );
      const uploadInput = getByRole('img', { name: 'Post cover' });
      expect(uploadInput.getAttribute('src')).toEqual('/some-fake-image.jpg');
    });

    it('shows the change and remove buttons', () => {
      const { getByRole, getByLabelText } = render(
        <ArticleCoverImage
          mainImage="/some-fake-image.jpg"
          onMainImageUrlChange={jest.fn()}
        />,
      );
      expect(getByLabelText('Change', { exact: false })).toBeInTheDocument();
      expect(getByRole('button', { name: 'Remove' })).toBeInTheDocument();
    });

    it('removes an existing cover image', async () => {
      const onMainImageUrlChange = jest.fn();
      const { queryByLabelText, queryByText, getByLabelText, getByRole } =
        render(
          <ArticleCoverImage
            mainImage="/some-fake-image.jpg"
            onMainImageUrlChange={onMainImageUrlChange}
          />,
        );

      expect(queryByText(/uploading.../i)).not.toBeInTheDocument();
      expect(queryByLabelText('Add a cover image')).not.toBeInTheDocument();
      expect(getByRole('img', { name: 'Post cover' })).toBeInTheDocument();
      expect(getByLabelText('Change', { exact: false })).toBeInTheDocument();

      const removeButton = getByRole('button', { name: 'Remove' });
      removeButton.click();

      expect(onMainImageUrlChange).toHaveBeenCalledTimes(1);

      // we can't test that the image is no longer there as it doesn't get removed in this component
      // This is handled in the article <Form /> component.
    });

    it('allows a user to change the image', async () => {
      fetch.mockResponse(
        JSON.stringify({
          image: ['/i/changed-fake-link.jpg'],
        }),
      );

      const onMainImageUrlChange = jest.fn();
      const {
        getByLabelText,
        queryByLabelText,
        queryByText,
        getByText,
        getByRole,
        queryByRole,
      } = render(
        <ArticleCoverImage
          mainImage="/some-fake-image.jpg"
          onMainImageUrlChange={onMainImageUrlChange}
        />,
      );

      expect(getByRole('img', { name: 'Post cover' })).toBeInTheDocument();
      expect(getByRole('button', { name: /remove/i })).toBeInTheDocument();

      const inputEl = getByLabelText('Change', { exact: false });
      const file = new File(['(⌐□_□)'], 'chucknorris.png', {
        type: 'image/png',
      });

      fireEvent.change(inputEl, { target: { files: [file] } });
      expect(inputEl.files[0]).toEqual(file);
      expect(inputEl.files).toHaveLength(1);

      expect(getByText(/uploading.../i)).toBeInTheDocument();
      expect(
        queryByRole('img', { name: 'Post cover' }),
      ).not.toBeInTheDocument();
      expect(queryByLabelText('Change')).not.toBeInTheDocument();
      expect(
        queryByRole('button', { name: /remove/i }),
      ).not.toBeInTheDocument();

      await waitForElementToBeRemoved(() => queryByText(/uploading.../i));

      expect(getByRole('img', { name: 'Post cover' })).toBeInTheDocument();
      expect(getByLabelText('Change', { exact: false })).toBeInTheDocument();
      expect(getByRole('button', { name: /remove/i })).toBeInTheDocument();

      expect(onMainImageUrlChange).toHaveBeenCalledTimes(1);
    });
  });

  it('displays an upload error when necessary', async () => {
    const onMainImageUrlChange = jest.fn();
    const { getByLabelText, findByText } = render(
      <ArticleCoverImage
        mainImage="/some-fake-image.jpg"
        onMainImageUrlChange={onMainImageUrlChange}
      />,
    );
    const inputEl = getByLabelText('Change', { exact: false });

    // Check the input validation settings
    expect(inputEl.getAttribute('accept')).toEqual('image/*');
    expect(Number(inputEl.dataset.maxFileSizeMb)).toEqual(25);

    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });

    fetch.mockReject({
      message: 'Some Fake Error',
    });
    fireEvent.change(inputEl, { target: { files: [file] } });

    const fakeError = await findByText(/some fake error/i);
    expect(fakeError).toBeInTheDocument();
  });

  describe('when rendered in native iOS with imageUpload support', () => {
    beforeAll(() => {
      stubNativeIOSCapabilities();
    });

    afterAll(() => {
      resetNativeIOSCapabilities();
    });

    it('should have no a11y violations when native iOS imageUpload support is available', async () => {
      const { container } = render(
        <ArticleCoverImage
          mainImage="/i/r5tvutqpl7th0qhzcw7f.png"
          onMainImageUrlChange={jest.fn()}
        />,
      );
      const results = await axe(container);
      expect(results).toHaveNoViolations();
    });

    it('does not contain the file input for uploading an image used only in the web browser experience', async () => {
      const { queryByTestId } = render(
        <ArticleCoverImage mainImage="" onMainImageUrlChange={jest.fn()} />,
      );
      expect(queryByTestId('cover-image-input')).not.toBeInTheDocument();
    });

    it('triggers a webkit messageHandler call when isNativeIOS', async () => {
      global.window.ForemMobile = { injectNativeMessage: jest.fn() };

      const { getByRole } = render(
        <ArticleCoverImage mainImage="" onMainImageUrlChange={jest.fn()} />,
      );
      const uploadButton = getByRole('button', { name: /Upload cover image/i });
      fireEvent.click(uploadButton);
      expect(
        global.window.ForemMobile.injectNativeMessage,
      ).toHaveBeenCalledTimes(1);
    });

    describe('when an image is uploaded', () => {
      it('successfully uploads an image', async () => {
        const onMainImageUrlChangeSpy = jest.fn();
        render(
          <ArticleCoverImage
            mainImage=""
            onMainImageUrlChange={onMainImageUrlChangeSpy}
          />,
        );

        // Fire a change event in the hidden input with JSON payload for success
        const fakeSuccessMessage = JSON.stringify({
          action: 'success',
          link: '/some-fake-image.jpg',
          namespace: 'coverUpload',
        });
        const event = createEvent(
          'ForemMobile',
          document,
          { detail: fakeSuccessMessage },
          { EventType: 'CustomEvent' },
        );
        fireEvent(document, event);

        expect(onMainImageUrlChangeSpy).toHaveBeenCalledTimes(1);
      });

      it('displays an upload error when necessary', async () => {
        const onMainImageUrlChange = jest.fn();
        const { findByText } = render(
          <ArticleCoverImage
            mainImage=""
            onMainImageUrlChange={onMainImageUrlChange}
          />,
        );

        const error = 'oh no!';

        // Fire a change event in the hidden input with JSON payload for an error
        const fakeErrorMessage = JSON.stringify({
          action: 'error',
          error,
          namespace: 'coverUpload',
        });
        const event = createEvent(
          'ForemMobile',
          document,
          { detail: fakeErrorMessage },
          { EventType: 'CustomEvent' },
        );
        fireEvent(document, event);

        const errorElement = await findByText(error);
        expect(errorElement).toBeInTheDocument();
        expect(onMainImageUrlChange).not.toHaveBeenCalled();
      });

      it('displays an uploading message', async () => {
        const onMainImageUrlChange = jest.fn();
        const { findByText } = render(
          <ArticleCoverImage
            mainImage=""
            onMainImageUrlChange={onMainImageUrlChange}
          />,
        );

        // Fire a change event in the hidden input with JSON payload for an error
        const fakeUploadingMessage = JSON.stringify({
          action: 'uploading',
          namespace: 'coverUpload',
        });
        const event = createEvent(
          'ForemMobile',
          document,
          { detail: fakeUploadingMessage },
          { EventType: 'CustomEvent' },
        );
        fireEvent(document, event);

        const uploadingText = await findByText(/Uploading.../i);
        expect(uploadingText).toBeInTheDocument();

        expect(onMainImageUrlChange).not.toHaveBeenCalled();
      });
    });
  });
});
