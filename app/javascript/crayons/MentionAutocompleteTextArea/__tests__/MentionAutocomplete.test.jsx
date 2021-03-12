import { h, Fragment, createRef } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';
import { MentionAutocomplete } from '../MentionAutocomplete';

describe('<MentionAutocomplete />', () => {
  const testTextAreaRef = createRef(null);
  const testTextArea = (
    <textarea ref={testTextAreaRef} aria-label="test text area" />
  );

  const mockFetchSuggestions = jest.fn();

  it('should have no a11y violations when rendered', async () => {
    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      };
    });

    const { container } = render(
      <Fragment>
        {testTextArea}
        <MentionAutocomplete
          textAreaRef={testTextAreaRef}
          fetchSuggestions={mockFetchSuggestions}
        />
      </Fragment>,
    );

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
