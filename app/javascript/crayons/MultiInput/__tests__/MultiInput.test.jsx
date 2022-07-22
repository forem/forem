import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';

import '@testing-library/jest-dom';

import { MultiInput } from '../MultiInput';

describe('<MultiInput />', () => {
  const getProps = () => ({
    labelText: 'Example label',
    placeholder: 'Add an email address...',
    regex: /([a-zA-Z0-9@.])/,
    validationRegex: /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/,
  });

  const renderMultiInput = (props = getProps()) =>
    render(<MultiInput {...props} />);

  const setup = (getByPlaceholderText) => {
    const input = getByPlaceholderText('Add an email address...');
    input.focus();
    return input;
  };

  it('renders default UI', () => {
    const { container } = renderMultiInput();
    expect(container.innerHTML).toMatchSnapshot();
  });

  describe('different keys', () => {
    it('adds selection when enter is pressed', async () => {
      const { getByPlaceholderText, getByRole } = renderMultiInput();
      const input = setup(getByPlaceholderText);

      await waitFor(() => userEvent.type(input, 'forem@gmail.com'));
      userEvent.type(input, '{enter}');
      await waitFor(() =>
        expect(
          getByRole('button', { name: 'Edit forem@gmail.com' }),
        ).toBeInTheDocument(),
      );
    });

    it('adds selection when comma is pressed', async () => {
      const { getByPlaceholderText, getByRole } = renderMultiInput();
      const input = setup(getByPlaceholderText);

      await waitFor(() => userEvent.type(input, 'forem@gmail.com'));
      userEvent.keyboard(',');
      await waitFor(() =>
        expect(
          getByRole('button', { name: 'Edit forem@gmail.com' }),
        ).toBeInTheDocument(),
      );
    });

    it('adds selection when space is pressed', async () => {
      const { getByPlaceholderText, getByRole } = renderMultiInput();
      const input = setup(getByPlaceholderText);

      await waitFor(() => userEvent.type(input, 'forem@gmail.com'));
      userEvent.keyboard(' ');
      await waitFor(() =>
        expect(
          getByRole('button', { name: 'Edit forem@gmail.com' }),
        ).toBeInTheDocument(),
      );
    });
  });

  it('edits a selection', async () => {
    const { getByLabelText, getByPlaceholderText, getByRole } =
      renderMultiInput();
    const input = setup(getByPlaceholderText);
    await waitFor(() => userEvent.type(input, 'forem@gmail.com'));
    userEvent.type(input, '{enter}');
    await waitFor(() =>
      getByRole('button', { name: 'Edit forem@gmail.com' }).click(),
    );

    // Input is focused and pre-filled with value
    const editInput = getByLabelText('Example label');
    await waitFor(() => expect(editInput).toHaveValue('forem@gmail.com'));
    expect(editInput).toHaveFocus();
  });

  it('deletes a selection', async () => {
    const { getByLabelText, getByPlaceholderText, getByRole, queryByRole } =
      renderMultiInput();
    const input = setup(getByPlaceholderText);
    await waitFor(() => userEvent.type(input, 'forem@gmail.com'));
    userEvent.type(input, '{enter}');
    await waitFor(() =>
      getByRole('button', { name: 'Remove forem@gmail.com' }).click(),
    );

    // Selection disappears
    await waitFor(() =>
      expect(
        queryByRole('button', { name: 'Remove forem@gmail.com' }),
      ).not.toBeInTheDocument(),
    );

    // Input is re-focused
    expect(getByLabelText('Example label')).toHaveFocus();
  });

  describe('callbacks', () => {
    it('passes an edit callback to custom selection template', async () => {
      const Selection = ({ name, onEdit }) => (
        <button onClick={onEdit}>Selected: {name}</button>
      );

      const { getByLabelText, getByRole, queryByRole, getByPlaceholderText } =
        render(
          <MultiInput
            labelText="Example label"
            placeholder="Add an email address..."
            inputRegex={/([a-zA-Z0-9@.])/}
            validationRegex={/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/}
            SelectionTemplate={Selection}
          />,
        );

      const input = getByPlaceholderText('Add an email address...');
      input.focus();
      await waitFor(() => userEvent.type(input, 'one'));
      userEvent.type(input, '{enter}');
      await waitFor(() =>
        getByRole('button', { name: 'Selected: one' }).click(),
      );

      // Selection disappears
      await waitFor(() =>
        expect(
          queryByRole('button', { name: 'Selected: one' }),
        ).not.toBeInTheDocument(),
      );

      // Input is focused and pre-filled with value
      const editInput = getByLabelText('Example label');
      await waitFor(() => expect(editInput).toHaveValue('one'));
      expect(editInput).toHaveFocus();
    });

    it('passes a deselect callback to custom selection template', async () => {
      const Selection = ({ name, onDeselect }) => (
        <button onClick={onDeselect}>Selected: {name}</button>
      );

      const { getByLabelText, getByRole, queryByRole, getByPlaceholderText } =
        render(
          <MultiInput
            labelText="Example label"
            placeholder="Add an email address..."
            inputRegex={/([a-zA-Z0-9@.])/}
            validationRegex={/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/}
            SelectionTemplate={Selection}
          />,
        );

      const input = getByPlaceholderText('Add an email address...');
      input.focus();
      await waitFor(() => userEvent.type(input, 'one'));
      userEvent.type(input, '{enter}');
      await waitFor(() =>
        getByRole('button', { name: 'Selected: one' }).click(),
      );

      // Selection disappears
      await waitFor(() =>
        expect(
          queryByRole('button', { name: 'Selected: one' }),
        ).not.toBeInTheDocument(),
      );

      // Input is re-focused
      expect(getByLabelText('Example label')).toHaveFocus();
    });
  });

  it('edits a previous selection (if exists) on backspace press in empty input', async () => {
    const { getByLabelText, getByRole, queryByRole, getByPlaceholderText } =
      renderMultiInput();

    const input = setup(getByPlaceholderText);
    await waitFor(() => userEvent.type(input, 'example'));
    userEvent.type(input, '{enter}');
    await waitFor(() =>
      expect(getByRole('button', { name: 'Edit example' })).toBeInTheDocument(),
    );

    // Selection should be present as passed as a default value
    const editInput = getByLabelText('Example label');
    editInput.focus();
    await userEvent.type(editInput, '{backspace}');

    await waitFor(() => expect(editInput).toHaveValue('example'));
    expect(queryByRole('button', { name: 'Edit example' })).toBeNull();
  });

  it('Adds a description to invalid entries', async () => {
    const { getByRole, getByPlaceholderText } = renderMultiInput();

    const input = setup(getByPlaceholderText);
    await waitFor(() => userEvent.type(input, 'example'));
    userEvent.type(input, '{enter}');
    await waitFor(() =>
      expect(getByRole('button', { name: 'Edit example' })).toBeInTheDocument(),
    );

    expect(
      getByRole('button', { name: 'Edit example' }),
    ).toHaveAccessibleDescription('Invalid entry');
  });

  it('Does not add a description to valid entries', async () => {
    const { getByRole, getByPlaceholderText } = renderMultiInput();

    const input = setup(getByPlaceholderText);
    await waitFor(() => userEvent.type(input, 'example@email.com'));
    userEvent.type(input, '{enter}');
    await waitFor(() =>
      expect(
        getByRole('button', { name: 'Edit example@email.com' }),
      ).toBeInTheDocument(),
    );

    expect(
      getByRole('button', { name: 'Edit example@email.com' }),
    ).not.toHaveAccessibleDescription('Invalid entry');
  });
});
