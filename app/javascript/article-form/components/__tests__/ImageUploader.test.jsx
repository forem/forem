import { h } from 'preact';
import { render, fireEvent, waitForElement } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import { ImageUploader } from '../ImageUploader';
import '@testing-library/jest-dom';

global.fetch = fetch;

describe('<ImageUploader />', () => {
  const fakeLinksResponse = JSON.stringify({
    links: ['/i/fake-link.jpg'],
  });

  const fakeErrorMessage = {
    message: 'Some Fake Error',
  };

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

  it('displays text to copy after upload', async () => {
    const { getByTitle, getByDisplayValue, getByLabelText } = render(
      <ImageUploader />,
    );
    const inputEl = getByLabelText(/Upload an image/i);

    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });

    fetch.mockResponse(fakeLinksResponse);
    fireEvent.change(inputEl, { target: { files: [file] } });

    expect(inputEl.files[0]).toEqual(file);
    expect(inputEl.files).toHaveLength(1);

    await waitForElement(() => getByTitle(/copy markdown for image/i));
    getByDisplayValue(/fake-link.jpg/i);
  });

  // TODO: 'Copied!' is always in the DOM, and so we cannot test that the visual implications of the copy when clicking on the copy icon

  it('displays an error when one occurs', async () => {
    const { getByText, getByLabelText } = render(<ImageUploader />);
    const inputEl = getByLabelText(/Upload an image/i);

    // Check the input validation settings
    expect(inputEl.getAttribute('accept')).toEqual('image/*');
    expect(Number(inputEl.dataset.maxFileSizeMb)).toEqual(25);

    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });

    fetch.mockReject(fakeErrorMessage);
    fireEvent.change(inputEl, {
      target: {
        files: [file],
      },
    });

    await waitForElement(() => getByText(/some fake error/i));
  });
});
