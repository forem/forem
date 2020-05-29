import { h } from 'preact';
import render from 'preact-render-to-json';
import { Title } from '../Title';

describe('<Title />', () => {
  it('renders properly', () => {
    const tree = render(
      <Title
        defaultValue="Test title"
        onChange={null}
        switchHelpContext={null}
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
