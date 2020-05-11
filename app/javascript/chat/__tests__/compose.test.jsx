import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
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

const handleKeyDownFake = e => {
  const enterPressed = e.keyCode === 13;
  if (!enterPressed) {
    textfieldIsEmpty = false;
  } else if (textfieldIsEmpty) {
    handleSubmitEmpty();
  } else {
    handleSubmitFake();
  }
};

const getCompose = tf => {
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

  describe('behavior with no message', () => {
    it('should click submit', () => {
      const context = shallow(getCompose(false));
      const btn = context.find('.messagecomposer__submit');

      expect(btn.simulate('click'));

      expect(submitNoMessage).toEqual(true);
      expect(submitWithMessage).toEqual(false);
      expect(textfieldIsEmpty).toEqual(true);
    });

    it('should press enter', () => {
      const context = shallow(getCompose(false));
      const input = context.find('.messagecomposer__input');

      const enter = { keyCode: 13 };
      expect(input.simulate('keyDown', enter));

      expect(submitNoMessage).toEqual(true);
      expect(submitWithMessage).toEqual(false);
      expect(textfieldIsEmpty).toEqual(true);
    });
  });

  describe('behavior with message', () => {
    it('should render and test snapshot', () => {
      const tree = render(getCompose(true));
      expect(tree).toMatchSnapshot();
    });

    it('should have proper elements, attributes and values', () => {
      const context = shallow(getCompose(true));
      expect(context.find('.messagecomposer').exists()).toEqual(true);

      const input = context.find('.messagecomposer__input');
      expect(input.exists()).toEqual(true);
      expect(input.text()).toEqual('');
      expect(input.attr('maxLength')).toEqual('1000');
      expect(input.attr('placeholder')).toEqual("Let's connect");

      const btn = context.find('.messagecomposer__submit');
      expect(btn.exists()).toEqual(true);
      expect(btn.text()).toEqual('SEND');
    });

    it('should click submit and check for empty textarea', () => {
      const context = shallow(getCompose(true));
      const input = context.find('.messagecomposer__input');
      const btn = context.find('.messagecomposer__submit');

      const someletter = { keyCode: 69 };

      expect(input.simulate('keyDown', someletter));
      expect(textfieldIsEmpty).toEqual(false);

      expect(btn.simulate('click'));

      expect(submitNoMessage).toEqual(false);
      expect(submitWithMessage).toEqual(true);
      expect(textfieldIsEmpty).toEqual(true);
    });

    it('should press enter and check for empty textarea', () => {
      const context = shallow(getCompose(true));
      const input = context.find('.messagecomposer__input');

      const someletter = { keyCode: 69 };
      expect(input.simulate('keyDown', someletter));
      const enter = { keyCode: 13 };
      expect(input.simulate('keyDown', enter));

      expect(submitNoMessage).toEqual(false);
      expect(submitWithMessage).toEqual(true);
      expect(textfieldIsEmpty).toEqual(true);
    });
  });
});
