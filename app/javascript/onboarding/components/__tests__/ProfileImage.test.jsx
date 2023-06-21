import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { act } from 'preact/test-utils';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { ProfileImage } from '../ProfileForm/ProfileImage';
import { processImageUpload } from '../actions';
import { validateFileInputs } from '../../../packs/validateFileInputs';

global.fetch = fetch;
global.URL.createObjectURL = jest.fn();

jest.mock('../../../packs/validateFileInputs');
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

describe('<ProfileImage /> uploading error', () => {
  beforeEach(() => {
    global.URL.createObjectURL = jest.fn();
    global.Image = class {
      constructor() {
        this.onload = null;
      }
      set src(val) {
        this.onload();
      }
    };
  });

  it('should not process the image upload when image size is larger than 4096x4096', async () => {
    validateFileInputs.mockImplementation(() => true);

    const onMainImageUrlChange = jest.fn();
    const { getByTestId, findByText } = render(
      <ProfileImage
        mainImage="/some-fake-image.jpg"
        onMainImageUrlChange={onMainImageUrlChange}
        userId="user1"
        name="User 1"
      />,
    );

    const fileInput = getByTestId('profile-image-input');
    const file = new File([], 'fakeimg.png', { type: 'image/png' });
    Object.defineProperty(file, 'size', { value: 5000000 });

    Object.defineProperty(Image.prototype, 'width', {
      value: 5000,
      writable: true,
    });
    Object.defineProperty(Image.prototype, 'height', {
      value: 5000,
      writable: true,
    });

    await act(async () => {
      fireEvent.change(fileInput, { target: { files: [file] } });
    });

    expect(
      await findByText('Image size should be less than or equal to 4096x4096.'),
    ).toBeInTheDocument();
  });

  it('should not show "Uploading..." when validateFileInputs returns false', async () => {
    validateFileInputs.mockImplementation(() => false);

    const onMainImageUrlChange = jest.fn();
    const { getByTestId, queryByText } = render(
      <ProfileImage
        mainImage="/some-fake-image.jpg"
        onMainImageUrlChange={onMainImageUrlChange}
        userId="user1"
        name="User 1"
      />,
    );

    const fileInput = getByTestId('profile-image-input');
    const file = new File([], 'fakeimg.png', { type: 'image/png' });

    await act(async () => {
      fireEvent.change(fileInput, { target: { files: [file] } });
    });

    expect(queryByText('Uploading...')).not.toBeInTheDocument();
  });
});
