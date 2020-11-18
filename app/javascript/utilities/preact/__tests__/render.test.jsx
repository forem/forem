import { render as preactRender } from 'preact';
import { instantClickRender } from '@utilities/preact/render';

jest.mock('preact');

describe('render', () => {
  beforeEach(() => {
    global.InstantClick = {
      on: jest.fn(),
    };
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  it('should mount a component', () => {
    const component = () => null;
    const container = document.createElement('section');
    instantClickRender(component, container);

    expect(preactRender).toHaveBeenCalledTimes(1);

    expect(preactRender).toHaveBeenCalledWith(component, container, undefined);
  });

  it('should mount a component with a node to be replaced', () => {
    const component = () => null;
    const container = document.createElement('section');
    const replaceNode = document.createElement('section');

    instantClickRender(component, container, replaceNode);

    expect(preactRender).toHaveBeenCalledTimes(1);

    expect(preactRender).toHaveBeenCalledWith(
      component,
      container,
      replaceNode,
    );
  });

  it(`should register an InstantClick.on('change') when the component renders`, () => {
    instantClickRender(() => null, document.createElement('section'));

    expect(InstantClick.on).toHaveBeenCalledTimes(1);
  });
});
