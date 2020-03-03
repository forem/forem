import { h } from 'preact';
import { deep } from 'preact-render-spy';
import Tags from '../tags';

describe('<Tags />', () => {
  beforeAll(() => {
    const environment = document.createElement('meta');
    environment.setAttribute('name', 'environment');
    document.body.appendChild(environment);
  });

  let tags;

  beforeEach(() => {
    tags = deep(<Tags defaultValue="defaultValue" listing />);
  });

  describe('handleKeyDown', () => {
    const preventDefaultMock = jest.fn();
    const createKeyDown = key => ({
      key,
      preventDefault: preventDefaultMock,
    });

    beforeEach(() => {
      preventDefaultMock.mockClear();
    });

    test('calls preventDefault on unused keyCode', () => {
      tags.find('#tag-input').simulate('keydown', createKeyDown('§'));
      tags.find('#tag-input').simulate('keydown', createKeyDown('\\'));
      expect(preventDefaultMock).toHaveBeenCalledTimes(2);
    });

    test('does not call preventDefault on used keyCode', () => {
      tags.find('#tag-input').simulate('keypress', createKeyDown('a'));
      tags.find('#tag-input').simulate('keydown', createKeyDown('1'));
      tags.find('#tag-input').simulate('keypress', createKeyDown(','));
      tags.find('#tag-input').simulate('keypress', createKeyDown('Enter'));
      expect(preventDefaultMock).not.toHaveBeenCalled();
    });
  });
});
