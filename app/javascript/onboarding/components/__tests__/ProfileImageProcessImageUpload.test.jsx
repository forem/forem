import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { processImageUpload } from '../actions';
import { validateFileInputs } from '../../../packs/validateFileInputs.js';

global.fetch = fetch;

jest.mock('../actions');
jest.mock('../../../packs/validateFileInputs.js', () => ({
  validateFileInputs: jest.fn(),
}));

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
