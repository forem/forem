import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import { userEvent } from '@testing-library/user-event';

import '@testing-library/jest-dom';
import { AutocompleteTriggerTextArea } from '../AutocompleteTriggerTextArea';

describe('<AutocompleteTriggerTextArea />', () => {
  const textArea = document.createElement('textarea');
  textArea.setAttribute('aria-label', 'test text area');
  textArea.setAttribute('id', 'test-text-area');
  textArea.value = 'some text';

  beforeAll(() => {
    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      };
    });
  });

  beforeEach(() => {
    document.body.appendChild(textArea);
  });

  it('should render when not replacing an element', () => {
    const { container } = render(
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        fetchSuggestions={async () => ({ result: [] })}
      />,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should render when replacing an element', () => {
    const { container } = render(
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        replaceElement={textArea}
        fetchSuggestions={async () => ({ result: [] })}
      />,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should switch to a combobox when trigger character is typed', async () => {
    const { queryByRole, getByRole } = render(
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        fetchSuggestions={async () => ({ result: [] })}
        aria-label="Example text area"
        id="some-id"
      />,
    );
    const textArea = getByRole('textbox', { name: 'Example text area' });
    expect(queryByRole('combobox')).not.toBeInTheDocument();
    expect(textArea).not.toHaveAttribute('aria-haspopup');
    expect(textArea).not.toHaveAttribute('aria-expanded');
    expect(textArea).not.toHaveAttribute('aria-owns');

    userEvent.type(textArea, '@');

    await waitFor(() => expect(getByRole('combobox')).toBeInTheDocument());
    expect(textArea).toHaveAttribute('aria-haspopup', 'listbox');
    expect(textArea).toHaveAttribute('aria-expanded', 'true');
    expect(textArea).toHaveAttribute('aria-owns', 'some-id-listbox');
  });

  it('should update aria-activedescendent on arrow press', async () => {
    const { getByRole, getAllByRole } = render(
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        fetchSuggestions={async () => [
          { value: 'option1', name: 'option1', username: 'username' },
          { value: 'option2', name: 'option2', username: 'username' },
          { value: 'option3', name: 'option3', username: 'username' },
        ]}
        aria-label="Example text area"
        id="some-id"
      />,
    );
    const textArea = getByRole('textbox', { name: 'Example text area' });
    userEvent.type(textArea, '@op');

    await waitFor(() => expect(getAllByRole('option')).toHaveLength(3));

    userEvent.keyboard('{arrowdown}');

    await waitFor(() =>
      expect(textArea).toHaveAttribute(
        'aria-activedescendant',
        'some-id-suggestion-0',
      ),
    );
    expect(getByRole('option', { name: 'option1 @username' })).toHaveAttribute(
      'aria-selected',
      'true',
    );

    userEvent.keyboard('{arrowdown}');

    await waitFor(() =>
      expect(textArea).toHaveAttribute(
        'aria-activedescendant',
        'some-id-suggestion-1',
      ),
    );
    expect(getByRole('option', { name: 'option2 @username' })).toHaveAttribute(
      'aria-selected',
      'true',
    );

    userEvent.keyboard('{arrowup}');

    await waitFor(() =>
      expect(textArea).toHaveAttribute(
        'aria-activedescendant',
        'some-id-suggestion-0',
      ),
    );
    expect(getByRole('option', { name: 'option1 @username' })).toHaveAttribute(
      'aria-selected',
      'true',
    );
  });

  it('should exit combobox mode and insert username when a selection is made', async () => {
    const { queryByRole, getByRole } = render(
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        fetchSuggestions={async () => [{ name: 'option1', value: 'option1' }]}
        aria-label="Example text area"
      />,
    );

    const textArea = getByRole('textbox', { name: 'Example text area' });
    userEvent.type(textArea, '@op');

    await waitFor(() => expect(getByRole('option')).toBeInTheDocument());
    getByRole('option').click();

    await waitFor(() =>
      expect(queryByRole('combobox')).not.toBeInTheDocument(),
    );
    expect(textArea).not.toHaveAttribute('aria-haspopup');
    expect(textArea).not.toHaveAttribute('aria-expanded');
    expect(textArea).not.toHaveAttribute('aria-owns');

    expect(textArea).toHaveValue('@option1 ');
  });

  it('should hide the pop-up options when Escape is pressed', async () => {
    const { queryByRole, getByRole } = render(
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        fetchSuggestions={async () => [{ name: 'option1', value: 'option1' }]}
        aria-label="Example text area"
      />,
    );

    expect(queryByRole('combobox')).not.toBeInTheDocument();
    userEvent.type(getByRole('textbox', { name: 'Example text area' }), '@op');

    await waitFor(() => expect(getByRole('option')).toBeInTheDocument());

    userEvent.type(
      getByRole('combobox', { name: 'Example text area' }),
      '{Escape}',
    );
    await waitFor(() => expect(queryByRole('option')).not.toBeInTheDocument());
  });

  it('should replace the given textarea', () => {
    const { getAllByRole } = render(
      <AutocompleteTriggerTextArea
        replaceElement={textArea}
        fetchSuggestions={async () => []}
      />,
    );

    // We should still have the same number of textareas on the page
    expect(getAllByRole('textbox')).toHaveLength(1);
  });

  it('should call onChange callback', async () => {
    const mockOnChange = jest.fn();
    const { getByRole } = render(
      <AutocompleteTriggerTextArea
        fetchSuggestions={async () => []}
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        aria-label="Example text area"
        onChange={mockOnChange}
      />,
    );

    userEvent.type(getByRole('textbox', { name: 'Example text area' }), 'x');
    await waitFor(() => expect(mockOnChange).toHaveBeenCalled());
  });

  it('should call onBlur callback', async () => {
    const mockOnBlur = jest.fn();
    const { getByRole } = render(
      <AutocompleteTriggerTextArea
        fetchSuggestions={async () => []}
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        aria-label="Example text area"
        onBlur={mockOnBlur}
      />,
    );

    const renderedTextArea = getByRole('textbox', {
      name: 'Example text area',
    });
    renderedTextArea.focus();
    renderedTextArea.blur();

    await waitFor(() => expect(mockOnBlur).toHaveBeenCalled());
  });

  it('should only show up to the maxSuggestions number, if specified', async () => {
    const { getByRole, getAllByRole, queryByRole } = render(
      <AutocompleteTriggerTextArea
        fetchSuggestions={async () => [
          { value: 'one' },
          { value: 'two' },
          { value: 'three' },
        ]}
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        aria-label="Example text area"
        maxSuggestions={2}
      />,
    );

    userEvent.type(
      getByRole('textbox', {
        name: 'Example text area',
      }),
      '@ab',
    );

    await waitFor(() => expect(getAllByRole('option')).toHaveLength(2));
    expect(queryByRole('option', { name: 'three' })).toBeNull();
  });
});
