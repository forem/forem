import { renderHook, act } from '@testing-library/preact-hooks';
import { fireEvent } from '@testing-library/preact';
import { usePasteImage } from '../pasteImage';

describe('usePasteImage', () => {
  it('listens for paste events on the set element', () => {
    const handlePasteImage = jest.fn();

    document.body.innerHTML = `
        <div id="paste-area"></div>
    `;
    const element = document.getElementById('paste-area');

    const {
      result: { current: setElement },
    } = renderHook(() => usePasteImage({ onPaste: handlePasteImage }));

    act(() => {
      setElement(element);
    });

    fireEvent.paste(element, { clipboardData: {} });
    expect(handlePasteImage).toHaveBeenCalled();
  });
});
