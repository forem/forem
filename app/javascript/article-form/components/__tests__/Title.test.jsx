import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import * as calculateHeightModule from '@utilities/calculateTextAreaHeight';
import { Title } from '../Title';

describe('<Title />', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

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

  it('sizes the title to the placeholder height initially and updates on input', () => {
    jest
      .spyOn(calculateHeightModule, 'calculateTextAreaHeight')
      .mockImplementation((el) => ({
        height: el.value ? 96 : 62,
      }));

    const { getByLabelText } = render(
      <Title
        defaultValue=""
        onChange={jest.fn()}
        switchHelpContext={jest.fn()}
      />,
    );

    const textarea = getByLabelText('Post Title');
    expect(textarea.style.minHeight).toBe('62px');
    expect(textarea.style.maxHeight).toBe('62px');

    fireEvent.input(textarea, { target: { value: 'A multi-line post title' } });
    expect(textarea.style.minHeight).toBe('96px');
    expect(textarea.style.maxHeight).toBe('96px');
  });
});
