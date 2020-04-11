import { h } from 'preact';
import { render } from 'preact-render-spy';
import ClearQueryButton from '../elements/clearQueryButton';

describe('<ClearQueryButton />', () => {
  const defaultProps = {
    onClick: () => {
      return 'onClick';
    },
  };

  it('Should match the snapshot', () => {
    const tree = render(<ClearQueryButton {...defaultProps} />);
    expect(tree).toMatchSnapshot();
  });
});
