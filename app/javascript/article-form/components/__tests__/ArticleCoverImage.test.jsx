import { h } from 'preact';
import { render, fireEvent, waitForElement } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { ArticleCoverImage } from '../ArticleCoverImage';

global.fetch = fetch;

describe('<ArticleCoverImage />', () => {
  const fakeLinksResponse = JSON.stringify({
    image: ['/i/changed-fake-link.jpg'],
  });
  const fakeErrorMessage = {
    message: 'Some Fake Error',
  };
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

    it('allows trigger the correct function for removal', async () => {
      const onMainImageUrlChange = jest.fn();
      const { getByText } = render(
        <ArticleCoverImage
          mainImage={'/some-fake-image.jpg'}
          onMainImageUrlChange={onMainImageUrlChange}
        />,
      );
      const removeButton = getByText('Remove');
      removeButton.click();
      expect(onMainImageUrlChange).toHaveBeenCalledTimes(1);
      // we can't test that the image is no longer there as it doesn't get removed in this component
    });

    it.skip('allows a user to change the image', async () => {
      const onMainImageUrlChange = jest.fn();
      const { getByLabelText } = render(
        <ArticleCoverImage
          mainImage={'/some-fake-image.jpg'}
          onMainImageUrlChange={onMainImageUrlChange}
        />,
      );
      const inputEl = getByLabelText('Change');

      const file = new File(['(⌐□_□)'], 'chucknorris.png', {
        type: 'image/png',
      });

      fetch.mockResponse(fakeLinksResponse);
      fireEvent.change(inputEl, { target: { files: [file] } });
      expect(inputEl.files[0]).toEqual(file);
      expect(inputEl.files).toHaveLength(1);
      expect(onMainImageUrlChange).toHaveBeenCalledTimes(1);

      // await waitForElement(() =>
      //   expect(onMainImageUrlChange).toHaveBeenCalledTimes(1),
      // );
    });
  });

  it('displays an upload error when necessary', async () => {
    const onMainImageUrlChange = jest.fn();
    const { getByText, getByLabelText } = render(
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

    fetch.mockReject(fakeErrorMessage);
    fireEvent.change(inputEl, { target: { files: [file] } });

    await waitForElement(() => getByText(/some fake error/i));
  });
});
