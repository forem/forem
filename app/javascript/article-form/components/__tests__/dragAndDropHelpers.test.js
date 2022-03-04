import {
  handleImageDrop,
  handleImageFailure,
  matchesDataTransferType,
} from '../dragAndDropHelpers';
import { addSnackbarItem } from '../../../Snackbar';
import { processImageUpload } from '../../actions';

jest.mock('../../../Snackbar');
jest.mock('../../actions');

function getDropZoneElement() {
  const textArea = document.createElement('textarea');
  const dropZoneElement = document.createElement('div');

  dropZoneElement.setAttribute('class', 'drop-area drop-area--active');

  dropZoneElement.appendChild(textArea);

  return textArea;
}

describe('Article drag and drop helpers', () => {
  beforeEach(() => {
    addSnackbarItem.mockReset();
  });

  describe('matchesDataTransferType', () => {
    it('should match data transfer type Files when no data transfer type to match is set', () => {
      expect(matchesDataTransferType(['Files'])).toEqual(true);
    });

    it('should match data transfer type when the type to match is in the list of types', () => {
      expect(
        matchesDataTransferType(
          ['SomeType', 'OtherType', 'BestType'],
          'SomeType',
        ),
      ).toEqual(true);
    });

    it('should not match data transfer type when the type to match is not in the list of types', () => {
      expect(
        matchesDataTransferType(
          ['SomeType', 'OtherType', 'BestType'],
          'NotInTheListType',
        ),
      ).toEqual(false);
    });
  });

  describe('handleImageFailure', () => {
    it('should handle image failure', () => {
      handleImageFailure(new Error('oh no'));

      expect(addSnackbarItem).toBeCalledTimes(1);
    });
  });

  describe('handleImageDrop', () => {
    it('should abort if data dropped is not files', () => {
      const successHandler = jest.fn();
      const failureHandler = jest.fn();
      const imageHandler = handleImageDrop(successHandler, failureHandler);
      const dropEvent = {
        preventDefault: jest.fn(),
        currentTarget: document.createElement('textarea'),
        dataTransfer: { types: ['NotFiles'] },
      };

      imageHandler(dropEvent);

      expect(processImageUpload).not.toHaveBeenCalled();
    });

    it('should abort if data dropped is multiple files', () => {
      const successHandler = jest.fn();
      const failureHandler = jest.fn();
      const imageHandler = handleImageDrop(successHandler, failureHandler);

      const dropEvent = {
        preventDefault: jest.fn(),
        currentTarget: getDropZoneElement(),
        dataTransfer: {
          types: ['Files'],
          files: [
            new File(['(⌐□_□)'], 'chucknorris.png', {
              type: 'image/png',
            }),
            new File(['ʕʘ̅͜ʘ̅ʔ'], 'vandamme.png', {
              type: 'image/png',
            }),
          ],
        },
      };

      imageHandler(dropEvent);

      expect(addSnackbarItem).toHaveBeenCalledTimes(1);
      expect(processImageUpload).not.toHaveBeenCalled();
    });

    it('should process image upload if data dropped is one image file', () => {
      const successHandler = jest.fn();
      const failureHandler = jest.fn();
      const imageHandler = handleImageDrop(successHandler, failureHandler);

      const dropEvent = {
        preventDefault: jest.fn(),
        currentTarget: getDropZoneElement(),
        dataTransfer: {
          types: ['Files'],
          files: [
            new File(['(⌐□_□)'], 'chucknorris.png', {
              type: 'image/png',
            }),
          ],
        },
      };

      imageHandler(dropEvent);

      expect(addSnackbarItem).not.toHaveBeenCalled();
      expect(processImageUpload).toHaveBeenCalledTimes(1);
    });
  });
});
