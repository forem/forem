import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { MentionAutocompleteTextArea } from '../MentionAutocompleteTextArea';

describe('<MentionAutocompleteTextArea />', () => {
  const textArea = document.createElement('textarea');
  textArea.setAttribute('aria-label', 'test text area');
  textArea.setAttribute('id', 'test-text-area');

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

  it('should replace the given textarea with a combobox textarea', () => {
    const { getByRole, getAllByLabelText } = render(
      <MentionAutocompleteTextArea
        replaceElement={textArea}
        fetchSuggestions={async () => ({ result: [] })}
      />,
    );

    const combobox = getByRole('combobox');
    expect(combobox).toBeInTheDocument();
    expect(combobox.id).toEqual('test-text-area');
    expect(combobox.getAttribute('aria-label')).toEqual('test text area');

    expect(getAllByLabelText('test text area')).toHaveLength(1);
  });
});
