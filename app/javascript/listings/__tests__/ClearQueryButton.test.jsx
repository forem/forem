import { h } from 'preact';
import render from 'preact-render-to-json';
import ClearQueryButton from '../components/ClearQueryButton';

describe('<ClearQueryButton />', () => {
  const getProps = () => ({
    onClick: () => {
      return 'onClick';
    },
  });

  it('Should match the snapshot', () => {
    const tree = render(<ClearQueryButton {...getProps()} />);
    expect(tree).toMatchSnapshot();
  });
});
