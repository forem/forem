import { initializeCommentPreview } from '../initializeCommentPreview';

describe('initializeCommentPreview', () => {
  beforeEach(() => {
    const button = document.createElement('button');
    button.classList.add('preview-toggle');
  });

  test('should call event listener when preview button exist', async () => {
    const button = document.createElement('button');
    button.classList.add('preview-toggle');
    button.addEventListener = jest.fn();
    initializeCommentPreview();

    expect(button.addEventListener).not.toHaveBeenCalled();
  });
});
