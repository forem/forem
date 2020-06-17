import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import Compose from '../compose';

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
  if (!enterPressed) {
    textfieldIsEmpty = false;
  } else if (textfieldIsEmpty) {
    handleSubmitEmpty();
  } else {
    handleSubmitFake();
  }
};

const getCompose = (tf) => {
  // true -> not empty, false -> empty
  if (tf) {
    return (
      <Compose
        handleSubmitOnClick={handleSubmitFake}
        handleKeyDown={handleKeyDownFake}
        activeChannelId={12345}
      />
    );
  }
  return (
    <Compose
      handleSubmitOnClick={handleSubmitEmpty}
      handleKeyDown={handleKeyDownFake}
      activeChannelId={12345}
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
      expect(input.getAttribute('placeholder')).toEqual('Write message...');

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
});
