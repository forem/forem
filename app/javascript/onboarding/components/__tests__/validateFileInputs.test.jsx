import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { ProfileImage } from '../ProfileForm/ProfileImage';
import { validateFileInputs } from '../../../packs/validateFileInputs.js';

global.fetch = fetch;

jest.mock('../../../packs/validateFileInputs.js', () => ({
  validateFileInputs: jest.fn(),
}));

describe('validateFileInputs.js', () => {
  it('should not show "Uploading..." when validateFileInputs returns false', () => {
    validateFileInputs.mockImplementation(() => false);

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

  it('should show "Uploading..." when validateFileInputs returns true', () => {
    validateFileInputs.mockImplementation(() => true);

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
});
