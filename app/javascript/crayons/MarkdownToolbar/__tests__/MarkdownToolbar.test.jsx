import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { MarkdownToolbar } from '../MarkdownToolbar';
import { BREAKPOINTS } from '@components/useMediaQuery';

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

  describe('small screen layout', () => {
    const smallScreenMediaQuery = `(max-width: ${BREAKPOINTS.Medium - 1}px)`;
    beforeEach(() => {
      global.window.matchMedia = jest.fn((query) => {
        return {
          matches: query === smallScreenMediaQuery,
          media: query,
          addListener: jest.fn(),
          removeListener: jest.fn(),
        };
      });
    });

    it('should render only 5 formatters in main toolbar', () => {
      const { getByLabelText, queryByLabelText } = render(<MarkdownToolbar />);

      expect(getByLabelText('Bold')).toBeInTheDocument();
      expect(getByLabelText('Italic')).toBeInTheDocument();
      expect(getByLabelText('Ordered list')).toBeInTheDocument();
      expect(getByLabelText('Unordered list')).toBeInTheDocument();
      expect(getByLabelText('Link')).toBeInTheDocument();

      expect(queryByLabelText('Heading')).not.toBeInTheDocument();
      expect(queryByLabelText('Quote')).not.toBeInTheDocument();
      expect(queryByLabelText('Code')).not.toBeInTheDocument();
      expect(queryByLabelText('Code block')).not.toBeInTheDocument();
      expect(queryByLabelText('Embed')).not.toBeInTheDocument();
      expect(queryByLabelText('Underline')).not.toBeInTheDocument();
      expect(queryByLabelText('Strikethrough')).not.toBeInTheDocument();
      expect(queryByLabelText('Line divider')).not.toBeInTheDocument();
    });

    it('should render remaining formatters in overflow menu', async () => {
      const { getByLabelText } = render(<MarkdownToolbar />);

      getByLabelText('More options').click();

      await waitFor(() =>
        expect(getByLabelText('Heading')).toBeInTheDocument(),
      );

      expect(getByLabelText('Quote')).toBeInTheDocument();
      expect(getByLabelText('Code')).toBeInTheDocument();
      expect(getByLabelText('Code block')).toBeInTheDocument();
      expect(getByLabelText('Embed')).toBeInTheDocument();
      expect(getByLabelText('Underline')).toBeInTheDocument();
      expect(getByLabelText('Strikethrough')).toBeInTheDocument();
      expect(getByLabelText('Line divider')).toBeInTheDocument();
    });
  });

  describe('large screen layout', () => {
    const largeScreenMediaQuery = `(min-width: ${
      BREAKPOINTS.Large
    }px) and (max-width: ${BREAKPOINTS.ExtraLarge - 1}px)`;
    beforeEach(() => {
      global.window.matchMedia = jest.fn((query) => {
        return {
          matches: query === largeScreenMediaQuery,
          media: query,
          addListener: jest.fn(),
          removeListener: jest.fn(),
        };
      });
    });

    it('should render only 7 formatters in the main toolbar', () => {
      const { getByLabelText, queryByLabelText } = render(<MarkdownToolbar />);

      expect(getByLabelText('Bold')).toBeInTheDocument();
      expect(getByLabelText('Italic')).toBeInTheDocument();
      expect(getByLabelText('Ordered list')).toBeInTheDocument();
      expect(getByLabelText('Unordered list')).toBeInTheDocument();
      expect(getByLabelText('Link')).toBeInTheDocument();
      expect(getByLabelText('Heading')).toBeInTheDocument();
      expect(getByLabelText('Quote')).toBeInTheDocument();

      expect(queryByLabelText('Code')).not.toBeInTheDocument();
      expect(queryByLabelText('Code block')).not.toBeInTheDocument();
      expect(queryByLabelText('Embed')).not.toBeInTheDocument();
      expect(queryByLabelText('Underline')).not.toBeInTheDocument();
      expect(queryByLabelText('Strikethrough')).not.toBeInTheDocument();
      expect(queryByLabelText('Line divider')).not.toBeInTheDocument();
    });

    it('should render remaining formatters in overflow menu', async () => {
      const { getByLabelText } = render(<MarkdownToolbar />);

      getByLabelText('More options').click();

      await waitFor(() => expect(getByLabelText('Code')).toBeInTheDocument());

      expect(getByLabelText('Code block')).toBeInTheDocument();
      expect(getByLabelText('Embed')).toBeInTheDocument();
      expect(getByLabelText('Underline')).toBeInTheDocument();
      expect(getByLabelText('Strikethrough')).toBeInTheDocument();
      expect(getByLabelText('Line divider')).toBeInTheDocument();
    });
  });

  describe('extra large screen layout', () => {
    beforeEach(() => {
      global.window.matchMedia = jest.fn((query) => {
        return {
          matches: false,
          media: query,
          addListener: jest.fn(),
          removeListener: jest.fn(),
        };
      });
    });

    it('should render 10 formatters in the main toolbar', () => {
      const { getByLabelText, queryByLabelText } = render(<MarkdownToolbar />);

      expect(getByLabelText('Bold')).toBeInTheDocument();
      expect(getByLabelText('Italic')).toBeInTheDocument();
      expect(getByLabelText('Ordered list')).toBeInTheDocument();
      expect(getByLabelText('Unordered list')).toBeInTheDocument();
      expect(getByLabelText('Link')).toBeInTheDocument();
      expect(getByLabelText('Heading')).toBeInTheDocument();
      expect(getByLabelText('Quote')).toBeInTheDocument();
      expect(getByLabelText('Code')).toBeInTheDocument();
      expect(getByLabelText('Code block')).toBeInTheDocument();
      expect(getByLabelText('Embed')).toBeInTheDocument();

      expect(queryByLabelText('Underline')).not.toBeInTheDocument();
      expect(queryByLabelText('Strikethrough')).not.toBeInTheDocument();
      expect(queryByLabelText('Line divider')).not.toBeInTheDocument();
    });

    it('should render remaining formatters in overflow menu', async () => {
      const { getByLabelText } = render(<MarkdownToolbar />);

      getByLabelText('More options').click();

      await waitFor(() =>
        expect(getByLabelText('Underline')).toBeInTheDocument(),
      );

      expect(getByLabelText('Strikethrough')).toBeInTheDocument();
      expect(getByLabelText('Line divider')).toBeInTheDocument();
    });
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
