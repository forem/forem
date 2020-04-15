import { h } from 'preact';
import { deep } from 'preact-render-spy';
import BodyMarkdown from '../elements/bodyMarkdown';

describe('<BodyMarkdown />', () => {
  const defaultProps = {
    onChange: () => {
      return 'onChange';
    },
    default: 'defaultValue',
  };

  const renderBodyMarkdown = (props = defaultProps) =>
    deep(<BodyMarkdown {...props} />);

  it('Should match the snapshot', () => {
    const tree = renderBodyMarkdown();
    expect(tree).toMatchSnapshot();
  });
});
