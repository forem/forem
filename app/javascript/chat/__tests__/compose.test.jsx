import { h } from 'preact';
import { render, fireEvent, createEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Compose } from '../compose';

let submitNoMessage = false;
let submitWithMessage = false;
let textfieldIsEmpty = true;

const handleSubmitEmpty = () => {
  submitNoMessage = true;
  submitWithMessage = false;
  textfieldIsEmpty = true;
};

const handleSubmitFake = () => {
  submitNoMessage = false;
  submitWithMessage = true;
  textfieldIsEmpty = true;
};

const handleKeyDownFake = (e) => {
  const enterPressed = e.keyCode === 13;
  const shiftPressed = e.shiftKey;
  if (!enterPressed) {
    textfieldIsEmpty = false;
  } else if (textfieldIsEmpty && !shiftPressed) {
    handleSubmitEmpty();
  } else if (textfieldIsEmpty && shiftPressed) {
    textfieldIsEmpty = false;
  } else {
    handleSubmitFake();
  }
};

const getCompose = (tf, props = {}) => {
  // true -> not empty, false -> empty
  if (tf) {
    return (
      <Compose
        handleSubmitOnClick={handleSubmitFake}
        handleKeyDown={handleKeyDownFake}
        activeChannelId={12345}
        {...props}
      />
    );
  }
  return (
    <Compose
      handleSubmitOnClick={handleSubmitEmpty}
      handleKeyDown={handleKeyDownFake}
      activeChannelId={12345}
      {...props}
    />
  );
};

describe('<Compose />', () => {
  afterEach(() => {
    submitNoMessage = false;
    submitWithMessage = false;
    textfieldIsEmpty = true;
  });

  it('should have no a11y violations', async () => {
    const { container } = render(getCompose(false));
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('behavior with no message', () => {
    it('should click submit', () => {
      const { getByText } = render(getCompose(false));
      const button = getByText(/Send/i);

      button.click();
      expect(submitNoMessage).toEqual(true);
      expect(submitWithMessage).toEqual(false);
      expect(textfieldIsEmpty).toEqual(true);
    });

    it('should press enter', () => {
      const { getByLabelText } = render(getCompose(false));
      const input = getByLabelText('Compose a message');

      fireEvent.keyDown(input, { keyCode: 13 });

      expect(submitNoMessage).toEqual(true);
      expect(submitWithMessage).toEqual(false);
      expect(textfieldIsEmpty).toEqual(true);
    });

    it('should pressed enter and shift', () => {
      const { getByLabelText } = render(getCompose(false));
      const input = getByLabelText('Compose a message');

      fireEvent.keyDown(input, { keyCode: 13 });
      fireEvent.keyDown(input, { keyCode: 16 });

      expect(textfieldIsEmpty).toEqual(false);
    });
  });

  describe('behavior with message', () => {
    it('should have no a11y violations', async () => {
      const { container } = render(getCompose(true));
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('should have proper elements, attributes and values', () => {
      const { getByLabelText, getByText } = render(getCompose(true));

      const input = getByLabelText('Compose a message');

      expect(input.textContent).toEqual('');
      expect(input.getAttribute('maxLength')).toEqual('1000');
      expect(input.getAttribute('placeholder')).toContain('Write message to');

      // Ensure send button is pressent
      getByText(/send/i);
    });

    it('should click submit and check for empty textarea', () => {
      const { getByLabelText, getByText } = render(getCompose(true));
      const input = getByLabelText('Compose a message');
      const sendButton = getByText(/send/i);

      fireEvent.keyDown(input, { keyCode: 69 });
      expect(textfieldIsEmpty).toEqual(false);

      sendButton.click();

      expect(submitNoMessage).toEqual(false);
      expect(submitWithMessage).toEqual(true);
      expect(textfieldIsEmpty).toEqual(true);
    });

    it('should press enter and check for empty textarea', () => {
      const { getByLabelText } = render(getCompose(true));
      const input = getByLabelText('Compose a message');

      fireEvent.keyDown(input, { keyCode: 69 });
      fireEvent.keyDown(input, { keyCode: 13 });

      expect(submitNoMessage).toEqual(false);
      expect(submitWithMessage).toEqual(true);
      expect(textfieldIsEmpty).toEqual(true);
    });
  });

  // Check for the actual input value after pressing enter
  it('should press enter and check for empty input', () => {
    const compose = getCompose(true);
    const { getByTestId, rerender } = render(compose);

    const input = getByTestId('messageform');

    fireEvent(input, createEvent('input', input, { target: { value: 'T' } }));

    expect(input.value).toBe('T');

    fireEvent.keyDown(input, { keyCode: 13 });

    rerender(compose);

    expect(input.value).toBe('');
  });

  // Check for the actual input value after clicking send
  it('should click send and check for empty input', () => {
    const compose = getCompose(true);
    const { getByTestId, getByText, rerender } = render(compose);

    const input = getByTestId('messageform');
    const sendButton = getByText(/send/i);

    fireEvent(input, createEvent('input', input, { target: { value: 'T' } }));

    expect(input.value).toBe('T');

    sendButton.click();

    rerender(compose);

    expect(input.value).toBe('');
  });

  // Check for the actual input value after saving an edit
  it('should click send edit and check for empty input', () => {
    const compose = getCompose(true, {
      markdownEdited: false,
      startEditing: true,
      editMessageMarkdown: 'Test',
      handleSubmitOnClickEdit: () => null,
    });
    const { getByTestId, getByText, rerender } = render(compose);

    const input = getByTestId('messageform');
    const saveButton = getByText(/save/i);

    expect(input.value).toBe('Test');

    saveButton.click();

    rerender(compose);

    expect(input.value).toBe('');
  });

  // Check for the actual input value after canceling an edit
  it('should click close edit and check for empty input', () => {
    const compose = getCompose(true, {
      markdownEdited: false,
      startEditing: true,
      editMessageMarkdown: 'Test',
      handleEditMessageClose: () => null,
    });
    const { getByTestId, getByText, rerender } = render(compose);

    const input = getByTestId('messageform');
    const closeButton = getByText(/close/i);

    expect(input.value).toBe('Test');

    closeButton.click();

    rerender(compose);

    expect(input.value).toBe('');
  });
});
