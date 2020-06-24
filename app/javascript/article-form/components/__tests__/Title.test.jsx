import { h } from 'preact';
import { render } from '@testing-library/preact';
import { Title } from '../Title';

describe('<Title />', () => {
  it('renders the textarea', () => {
    const { getByPlaceholderText } = render(
      <Title
        defaultValue="Test title"
        onChange={null}
        switchHelpContext={null}
      />,
    );
    getByPlaceholderText(/post title/i, { selector: 'textarea' });
  });
});
