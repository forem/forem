import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { MentionAutocompleteTextArea } from '../MentionAutocompleteTextArea';

describe('<MentionAutocompleteTextArea />', () => {
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

  it('should render', () => {
    const { container } = render(
      <MentionAutocompleteTextArea
        replaceElement={textArea}
        fetchSuggestions={async () => ({ result: [] })}
      />,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should replace the given textarea with a hidden combobox and a plain textarea', () => {
    const { getByRole } = render(
      <MentionAutocompleteTextArea
        replaceElement={textArea}
        fetchSuggestions={async () => ({ result: [] })}
      />,
    );

    const combobox = getByRole('combobox');

    waitFor(() => expect(combobox).not.toBeVisible());
    expect(combobox.id).toEqual('test-text-area');
    expect(combobox.value).toEqual('some text');
    expect(combobox.getAttribute('aria-label')).toEqual('test text area');

    const textarea = getByRole('textbox');
    expect(textarea).toBeVisible();
    expect(textarea.id).toEqual('test-text-area');
    expect(textarea.value).toEqual('some text');
    expect(textarea.getAttribute('aria-label')).toEqual('test text area');
  });
});
