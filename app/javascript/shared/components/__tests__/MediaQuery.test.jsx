import { h } from 'preact';
import { render } from '@testing-library/preact';
import { MediaQuery } from '@components/MediaQuery';

describe('<MediaQuery />', () => {
  it('should call the render prop', () => {
    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      };
    });

    const renderProp = jest.fn();

    render(<MediaQuery query="some media query" render={renderProp} />);

    expect(renderProp).toHaveBeenCalledTimes(1);
  });
});
