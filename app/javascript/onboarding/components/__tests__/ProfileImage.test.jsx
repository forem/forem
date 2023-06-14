import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { ProfileImage } from '../ProfileForm/ProfileImage';
import { processImageUpload } from '../actions';
import { validateFileInputs } from '../../../packs/validateFileInputs';

global.fetch = fetch;
global.URL.createObjectURL = jest.fn();

jest.mock('../actions');
jest.mock('../../../packs/validateFileInputs.js', () => ({
  validateFileInputs: jest.fn(),
}));

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
    const { getByRole } = render(
      <ProfileImage
        mainImage="/some-fake-image.jpg"
        onMainImageUrlChange={jest.fn()}
        userId="user1"
        name="User 1"
      />,
    );
    const uploadInput = getByRole('img', { name: 'profile' });
    expect(uploadInput.getAttribute('src')).toEqual('/some-fake-image.jpg');
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
});

describe('processImageUpload', () => {
  it('should not process the image upload when validateFileInputs returns false', () => {
    validateFileInputs.mockImplementation(() => false);

    const handleImageUploading = jest.fn();
    const handleImageSuccess = jest.fn();
    const handleImageFailure = jest.fn();

    processImageUpload(
      ['mock-image'],
      handleImageUploading,
      handleImageSuccess,
      handleImageFailure,
      'user1',
    );

    expect(handleImageUploading).not.toHaveBeenCalled();
  });
});
