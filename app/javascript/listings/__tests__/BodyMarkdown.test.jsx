import { h } from 'preact';
import render from 'preact-render-to-json';
import BodyMarkdown from '../components/BodyMarkdown';

describe('<BodyMarkdown />', () => {
  const getProps = () => ({
    onChange: () => {
      return 'onChange';
    },
    default: 'defaultValue',
  });

  const renderBodyMarkdown = () => render(<BodyMarkdown {...getProps()} />);

  it('Should match the snapshot', () => {
    const tree = renderBodyMarkdown();
    expect(tree).toMatchSnapshot();
  });
});
