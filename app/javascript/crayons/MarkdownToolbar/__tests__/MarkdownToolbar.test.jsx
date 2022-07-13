import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { MarkdownToolbar } from '../MarkdownToolbar';

describe('<MarkdownToolbar />', () => {
  beforeEach(() => {
    global.Runtime = {
      getOSKeyboardModifierKeyString: jest.fn(() => 'cmd'),
      isNativeIOS: jest.fn(() => {
        return false;
      }),
    };

    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      };
    });
  });

  it('should have no a11y violations when rendered', async () => {
    const { container } = render(<MarkdownToolbar />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render core syntax formatters in main toolbar', () => {
    const { getByLabelText } = render(<MarkdownToolbar />);

    expect(getByLabelText('Bold')).toBeInTheDocument();
    expect(getByLabelText('Italic')).toBeInTheDocument();
    expect(getByLabelText('Ordered list')).toBeInTheDocument();
    expect(getByLabelText('Unordered list')).toBeInTheDocument();
    expect(getByLabelText('Heading')).toBeInTheDocument();
    expect(getByLabelText('Quote')).toBeInTheDocument();
    expect(getByLabelText('Code')).toBeInTheDocument();
    expect(getByLabelText('Code block')).toBeInTheDocument();
    expect(getByLabelText('Embed')).toBeInTheDocument();
  });

  it('should render an overflow menu with secondary formatters', async () => {
    const { getByLabelText } = render(<MarkdownToolbar />);

    getByLabelText('More options').click();

    await waitFor(() =>
      expect(getByLabelText('Underline')).toBeInTheDocument(),
    );
    expect(getByLabelText('Strikethrough')).toBeInTheDocument();
    expect(getByLabelText('Line divider')).toBeInTheDocument();
  });

  it('should render any custom secondary toolbar elements', async () => {
    const exampleLink = <a href="/something">Some link</a>;
    const exampleButton = <button>Some button</button>;

    const { getByLabelText, getByRole } = render(
      <MarkdownToolbar
        additionalSecondaryToolbarElements={[exampleButton, exampleLink]}
      />,
    );

    getByLabelText('More options').click();

    await waitFor(() =>
      expect(getByLabelText('Underline')).toBeInTheDocument(),
    );

    expect(getByRole('menuitem', { name: 'Some link' })).toBeInTheDocument();
    expect(getByRole('menuitem', { name: 'Some button' })).toBeInTheDocument();
  });
});
