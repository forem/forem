import { h } from 'preact';
import {
  render,
  fireEvent,
  waitForElementToBeRemoved,
} from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { ArticleCoverImage } from '../ArticleCoverImage';

global.fetch = fetch;

describe('<ArticleCoverImage />', () => {
  beforeEach(() => {
    global.Runtime = {
      isNativeIOS: jest.fn(() => {
        return false;
      }),
    };
  });

  it('should have no a11y violations', async () => {
    // TODO: The axe custom rules here should be removed when the below issue is fixed
    // https://github.com/forem/forem/issues/13947
    const customAxeRules = {
      'nested-interactive': { enabled: false },
    };

    const { container } = render(
      <ArticleCoverImage
        mainImage="/i/r5tvutqpl7th0qhzcw7f.png"
        onMainImageUrlChange={jest.fn()}
      />,
    );
    const results = await axe(container, { rules: customAxeRules });
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
      const { getByAltText } = render(
        <ArticleCoverImage
          mainImage={'/some-fake-image.jpg'}
          onMainImageUrlChange={jest.fn()}
        />,
      );
      const uploadInput = getByAltText('Post cover');
      expect(uploadInput.getAttribute('src')).toEqual('/some-fake-image.jpg');
    });

    it('shows the change and remove buttons', () => {
      const { queryByText } = render(
        <ArticleCoverImage
          mainImage={'/some-fake-image.jpg'}
          onMainImageUrlChange={jest.fn()}
        />,
      );
      expect(queryByText('Change')).toBeDefined();
      expect(queryByText('Remove')).toBeDefined();
    });

    it('removes an existing cover image', async () => {
      const onMainImageUrlChange = jest.fn();
      const { getByText, queryByLabelText, queryByText } = render(
        <ArticleCoverImage
          mainImage={'/some-fake-image.jpg'}
          onMainImageUrlChange={onMainImageUrlChange}
        />,
      );

      expect(queryByText(/uploading.../i)).toBeNull();

      expect(queryByLabelText('Add a cover image')).toBeNull();
      expect(queryByLabelText('Post cover')).toBeDefined();
      expect(queryByLabelText('Change')).toBeDefined();

      const removeButton = getByText('Remove');
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
      const { getByLabelText, queryByLabelText, queryByText } = render(
        <ArticleCoverImage
          mainImage={'/some-fake-image.jpg'}
          onMainImageUrlChange={onMainImageUrlChange}
        />,
      );

      expect(queryByLabelText('Post cover')).toBeDefined();
      expect(queryByLabelText(/remove/i)).toBeDefined();

      const inputEl = getByLabelText('Change');
      const file = new File(['(⌐□_□)'], 'chucknorris.png', {
        type: 'image/png',
      });

      fireEvent.change(inputEl, { target: { files: [file] } });
      expect(inputEl.files[0]).toEqual(file);
      expect(inputEl.files).toHaveLength(1);

      expect(queryByText(/uploading.../i)).toBeDefined();
      expect(queryByLabelText('Post cover')).toBeNull();
      expect(queryByLabelText('Change')).toBeNull();
      expect(queryByLabelText(/remove/i)).toBeNull();

      await waitForElementToBeRemoved(() => queryByText(/uploading.../i));

      expect(queryByLabelText('Post cover')).toBeDefined();
      expect(queryByLabelText('Change')).toBeDefined();
      expect(queryByLabelText(/remove/i)).toBeDefined();

      expect(onMainImageUrlChange).toHaveBeenCalledTimes(1);
    });
  });

  it('displays an upload error when necessary', async () => {
    const onMainImageUrlChange = jest.fn();
    const { getByLabelText, findByText } = render(
      <ArticleCoverImage
        mainImage={'/some-fake-image.jpg'}
        onMainImageUrlChange={onMainImageUrlChange}
      />,
    );
    const inputEl = getByLabelText('Change');

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

    await findByText(/some fake error/i);
  });

  describe('when rendered in native iOS with imageUpload support', () => {
    beforeEach(() => {
      global.Runtime = {
        isNativeIOS: jest.fn((namespace) => {
          return namespace === 'imageUpload';
        }),
      };
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
      const { queryByText } = render(
        <ArticleCoverImage mainImage="" onMainImageUrlChange={jest.fn()} />,
      );
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

      const { queryByLabelText } = render(<ArticleCoverImage mainImage="" />);
      const uploadButton = queryByLabelText(/Upload cover image/i);
      uploadButton.click();
      expect(
        window.webkit.messageHandlers.imageUpload.postMessage,
      ).toHaveBeenCalledTimes(1);
    });

    describe('when an image is uploaded', () => {
      it('successfully uploads an image', async () => {
        const onMainImageUrlChange = jest.fn();
        const { container } = render(
          <ArticleCoverImage
            mainImage=""
            onMainImageUrlChange={onMainImageUrlChange}
          />,
        );
        const nativeInput = container.querySelector(
          '#native-cover-image-upload-message',
        );

        // Fire a change event in the hidden input with JSON payload for success
        const fakeSuccessMessage = `{ "action": "success", "link": "/some-fake-image.jpg" }`;
        fireEvent.change(nativeInput, {
          target: { value: fakeSuccessMessage },
        });

        expect(onMainImageUrlChange).toHaveBeenCalledTimes(1);
      });

      it('displays an upload error when necessary', async () => {
        const onMainImageUrlChange = jest.fn();
        const { container, findByText } = render(
          <ArticleCoverImage
            mainImage=""
            onMainImageUrlChange={onMainImageUrlChange}
          />,
        );
        const nativeInput = container.querySelector(
          '#native-cover-image-upload-message',
        );

        const error = 'oh no!';

        // Fire a change event in the hidden input with JSON payload for an error
        const fakeErrorMessage = JSON.stringify({ action: 'error', error });
        fireEvent.change(nativeInput, {
          target: { value: fakeErrorMessage },
        });

        await findByText(error);

        expect(onMainImageUrlChange).not.toHaveBeenCalled();
      });

      it('displays an uploading message', async () => {
        const onMainImageUrlChange = jest.fn();
        const { container, findByText } = render(
          <ArticleCoverImage
            mainImage=""
            onMainImageUrlChange={onMainImageUrlChange}
          />,
        );
        const nativeInput = container.querySelector(
          '#native-cover-image-upload-message',
        );

        // Fire a change event in the hidden input with JSON payload for an error
        const fakeUploadingMessage = JSON.stringify({ action: 'uploading' });
        fireEvent.change(nativeInput, {
          target: { value: fakeUploadingMessage },
        });

        await findByText(/Uploading.../i);

        expect(onMainImageUrlChange).not.toHaveBeenCalled();
      });
    });
  });
});
