import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';

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

  it('should switch to combobox role when trigger character is typed', async () => {
    const { queryByRole, getByRole } = render(
      <AutocompleteTriggerTextArea
        triggerCharacter="@"
        searchInstructionsMessage="Type to search for a user"
        fetchSuggestions={async () => ({ result: [] })}
        aria-label="Example text area"
      />,
    );

    expect(queryByRole('combobox')).not.toBeInTheDocument();
    userEvent.type(getByRole('textbox', { name: 'Example text area' }), '@');

    await waitFor(() => expect(getByRole('combobox')).toBeInTheDocument());
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

    expect(queryByRole('combobox')).not.toBeInTheDocument();
    userEvent.type(getByRole('textbox', { name: 'Example text area' }), '@op');

    await waitFor(() => expect(getByRole('option')).toBeInTheDocument());
    getByRole('option').click();

    await waitFor(() =>
      expect(queryByRole('combobox')).not.toBeInTheDocument(),
    );
    expect(getByRole('textbox', { name: 'Example text area' })).toHaveValue(
      '@option1 ',
    );
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
});
