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
  beforeEach(() => {
    // Mock window.currentUser
    global.window.currentUser = {};
  });

  afterEach(() => {
    // Clean up
    delete global.window.currentUser;
  });

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

  it('displays a generate with AI button when there is no main image', () => {
    const { getByTestId } = render(
      <ArticleCoverImage mainImage="" onMainImageUrlChange={jest.fn()} coverImageHeight="420" coverImageCrop="no_crop" aiAvailable={true} />,
    );
    const generateButton = getByTestId('generate-ai-image-btn');
    expect(generateButton).toBeInTheDocument();
    expect(generateButton.textContent).toContain('Generate Image');
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
        coverImageHeight="420"
        coverImageCrop="no_crop"
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

  describe('AI image generation', () => {
    beforeEach(() => {
      fetch.resetMocks();
    });

    it('opens the AI prompt modal when generate button is clicked', async () => {
      const { getByTestId, findByTestId } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={jest.fn()}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      const modal = await findByTestId('ai-prompt-modal');
      expect(modal).toBeInTheDocument();
    });

    it('displays the AI prompt input in the modal', async () => {
      const { getByTestId, findByTestId } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={jest.fn()}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      const promptInput = await findByTestId('ai-prompt-input');
      expect(promptInput).toBeInTheDocument();
      expect(promptInput.tagName).toEqual('TEXTAREA');
    });

    it('generates an AI image successfully', async () => {
      const mockImageUrl = 'https://example.com/generated-image.png';
      fetch.mockResponseOnce(
        JSON.stringify({ url: mockImageUrl }),
      );

      const onMainImageUrlChange = jest.fn();
      const { getByTestId, findByTestId, queryByText } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={onMainImageUrlChange}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      // Open modal
      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      // Enter prompt
      const promptInput = await findByTestId('ai-prompt-input');
      fireEvent.input(promptInput, { target: { value: 'A beautiful sunset' } });

      // Submit
      const submitButton = getByTestId('generate-submit-btn');
      fireEvent.click(submitButton);

      // Wait for generation to complete
      await waitForElementToBeRemoved(() => queryByText(/generating.../i));

      expect(onMainImageUrlChange).toHaveBeenCalledWith({
        links: [mockImageUrl],
      });
      expect(fetch).toHaveBeenCalledWith('/ai_image_generations', expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'Content-Type': 'application/json',
        }),
        body: JSON.stringify({
          prompt: 'A beautiful sunset',
        }),
      }));
    });

    it('displays an error when AI generation fails', async () => {
      fetch.mockResponseOnce(
        JSON.stringify({ error: 'Generation failed' }),
      );

      const { getByTestId, findByTestId, findByText } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={jest.fn()}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      // Open modal
      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      // Enter prompt
      const promptInput = await findByTestId('ai-prompt-input');
      fireEvent.input(promptInput, { target: { value: 'A beautiful sunset' } });

      // Submit
      const submitButton = getByTestId('generate-submit-btn');
      fireEvent.click(submitButton);

      // Wait for error
      const errorMessage = await findByText(/generation failed/i);
      expect(errorMessage).toBeInTheDocument();
    });

    it('can close the AI prompt modal', async () => {
      const { getByTestId, findByTestId, queryByTestId } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={jest.fn()}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      // Open modal
      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      const modal = await findByTestId('ai-prompt-modal');
      expect(modal).toBeInTheDocument();

      // Click cancel
      const cancelButton = modal.querySelector('button[type="button"]');
      fireEvent.click(cancelButton);

      // Modal should be closed
      expect(queryByTestId('ai-prompt-modal')).not.toBeInTheDocument();
    });

    it('displays footer with GitHub link in the modal', async () => {
      const { getByTestId, findByTestId, getByText } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={jest.fn()}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      const modal = await findByTestId('ai-prompt-modal');
      expect(modal).toBeInTheDocument();

      // Check for footer text
      expect(getByText(/Curious how this works/i)).toBeInTheDocument();
      expect(getByText(/open source/i)).toBeInTheDocument();

      // Check for GitHub link
      const githubLink = modal.querySelector('a[href*="github.com"]');
      expect(githubLink).toBeInTheDocument();
      expect(githubLink.href).toContain('github.com/forem/forem/blob/main/app/services/ai/image_generator.rb');
      expect(githubLink.target).toBe('_blank');
      expect(githubLink.rel).toContain('noopener');
    });

    it('disables submit button when prompt is empty', async () => {
      const { getByTestId, findByTestId } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={jest.fn()}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      // Open modal
      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      const submitButton = await findByTestId('generate-submit-btn');
      expect(submitButton).toBeDisabled();
    });

    it('prevents closing modal while generating', async () => {
      fetch.mockResponseOnce(
        () => new Promise(resolve => setTimeout(() => resolve({ body: JSON.stringify({ url: 'test.png' }) }), 100))
      );

      const { getByTestId, findByTestId, queryByRole } = render(
        <ArticleCoverImage
          mainImage=""
          onMainImageUrlChange={jest.fn()}
          coverImageHeight="420"
          coverImageCrop="no_crop"
          aiAvailable={true}
        />,
      );

      // Open modal
      const generateButton = getByTestId('generate-ai-image-btn');
      fireEvent.click(generateButton);

      // Enter prompt and submit
      const promptInput = await findByTestId('ai-prompt-input');
      fireEvent.input(promptInput, { target: { value: 'Test prompt' } });

      const submitButton = getByTestId('generate-submit-btn');
      fireEvent.click(submitButton);

      // Close button should not be visible during generation
      expect(queryByRole('button', { name: 'Close' })).not.toBeInTheDocument();
    });
  });

  describe('when rendered in native iOS with imageUpload support', () => {
    beforeAll(() => {
      stubNativeIOSCapabilities();
      global.window.currentUser = {};
    });

    afterAll(() => {
      resetNativeIOSCapabilities();
      delete global.window.currentUser;
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
