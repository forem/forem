import { h } from 'preact';
import { render } from 'preact-render-spy';
import NextPageButton from '../components/NextPageButton';

describe('<NextPageButton />', () => {
  const defaultProps = {
    onClick: () => {
      return 'onClick';
    },
  };

  it('Should match the snapshot', () => {
    const tree = render(<NextPageButton {...defaultProps} />);
    expect(tree).toMatchSnapshot();
  });
});
