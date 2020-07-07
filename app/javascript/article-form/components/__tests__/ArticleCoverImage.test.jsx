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
});
