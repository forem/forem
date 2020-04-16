import { h } from 'preact';
import { render } from 'preact-render-spy';
import ModalBackground from '../components/ModalBackground';

describe('<ModalBackground />', () => {
  const defaultProps = {
    onClick: () => {
      return 'onClick';
    },
  };

  it('Should match the snapshot', () => {
    const tree = render(<ModalBackground {...defaultProps} />);
    expect(tree).toMatchSnapshot();
  });
});
