import { h } from 'preact';
import { deep } from 'preact-render-spy';
import Tags from '../tags';

describe('<Tags />', () => {
  beforeAll(() => {
    const publicId = document.createElement('meta');
    publicId.setAttribute('name', 'algolia-public-id');
    const publicKey = document.createElement('meta');
    publicKey.setAttribute('name', 'algolia-public-key');
    const environment = document.createElement('meta');
    environment.setAttribute('name', 'environment');
    document.body.appendChild(publicId);
    document.body.appendChild(publicKey);
    document.body.appendChild(environment);
    global.algoliasearch = () => ({
      initIndex: () => 'initIndex',
    });
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
