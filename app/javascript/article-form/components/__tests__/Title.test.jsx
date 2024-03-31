import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Title } from '../Title';

describe('<Title />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <Title
        defaultValue="Test title"
        onChange={null}
        switchHelpContext={null}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders the textarea', () => {
    const { queryByPlaceholderText } = render(
      <Title
        defaultValue="Test title"
        onChange={null}
        switchHelpContext={null}
      />,
    );

    expect(
      queryByPlaceholderText(/post title/i, { selector: 'textarea' }),
    ).toExist();
  });
});
