import { h } from 'preact';
import { render, fireEvent, waitFor } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { ProfileImage } from '../ProfileForm/ProfileImage';

global.fetch = fetch;

describe('<ProfileImage />', () => {
  it('should render correctly', () => {
    const onMainImageUrlChangeMock = jest.fn();
    const { getByTestId } = render(
      <ProfileImage
        onMainImageUrlChange={onMainImageUrlChangeMock}
        mainImage="test.jpg"
        userId="1"
        name="Test User"
      />,
    );

    expect(getByTestId('profile-image-input')).toBeInTheDocument();
  });

  it('should have no a11y violations', async () => {
    const { container } = render(
      <ProfileImage
        mainImage="/i/r5tvutqpl7th0qhzcw7f.png"
        onMainImageUrlChange={jest.fn()}
        userId="user1"
        name="User 1"
      />,
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('displays an upload input when the image is not being uploaded', () => {
    const { getByLabelText } = render(
      <ProfileImage
        mainImage=""
        onMainImageUrlChange={jest.fn()}
        userId="user1"
        name="User 1"
      />,
    );
    const uploadInput = getByLabelText(/edit profile image/i);
    expect(uploadInput.getAttribute('type')).toEqual('file');
  });

  it('shows the uploaded image', () => {
    const { getByRole, queryByText } = render(
      <ProfileImage
        mainImage="/some-fake-image.jpg"
        onMainImageUrlChange={jest.fn()}
        userId="user1"
        name="User 1"
      />,
    );
    const uploadInput = getByRole('img', { name: 'profile' });
    expect(uploadInput.getAttribute('src')).toEqual('/some-fake-image.jpg');
    expect(queryByText('Uploading...')).not.toBeInTheDocument();
  });

  it('shows the "Uploading..." message when an image is being uploaded', () => {
    const { getByLabelText, getByText } = render(
      <ProfileImage
        mainImage=""
        onMainImageUrlChange={jest.fn()}
        userId="user1"
        name="User 1"
      />,
    );

    const file = new File(['file content'], 'filename.png', {
      type: 'image/png',
    });

    const uploadInput = getByLabelText(/edit profile image/i);
    fireEvent.change(uploadInput, { target: { files: [file] } });

    expect(getByText('Uploading...')).toBeInTheDocument();
  });

  it('displays an upload error when necessary', async () => {
    const { getByLabelText, findByText, queryByText } = render(
      <ProfileImage
        onMainImageUrlChange={jest.fn()}
        mainImage="test.png"
        userId="1"
        name="Test User"
      />,
    );
    const inputEl = getByLabelText('Edit profile image', { exact: false });

    expect(inputEl.getAttribute('accept')).toEqual('image/*');

    const file = new File(['(⌐□_□)'], 'chucknorris.png', {
      type: 'image/png',
    });
    fetch.mockReject({
      message: 'Some Fake Error',
    });

    fireEvent.change(inputEl, { target: { files: [file] } });
    const fakeError = await findByText(/some fake error/i);
    expect(fakeError).toBeInTheDocument();
    expect(queryByText('Uploading...')).not.toBeInTheDocument();
  });

  it('should handle image upload correctly', async () => {
    const onMainImageUrlChangeMock = jest.fn();
    const { getByTestId } = render(
      <ProfileImage
        onMainImageUrlChange={onMainImageUrlChangeMock}
        mainImage=""
        userId="user1"
        name="User 1"
      />,
    );

    const file = new File(['file content'], 'filename.png', {
      type: 'image/png',
    });

    const uploadInput = getByTestId('profile-image-input');
    fireEvent.change(uploadInput, { target: { files: [file] } });

    await waitFor(() => {
      expect(uploadInput.files).toHaveLength(1);
    });
  });
});
