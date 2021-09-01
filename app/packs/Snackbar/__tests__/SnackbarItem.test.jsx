import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { SnackbarItem } from '..';

describe('<SnackbarItem />', () => {
  it('should have no a11y violations when displaying only a message', async () => {
    const { container } = render(
      <SnackbarItem message="File uploaded successfully" />,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when displaying a message and one action', async () => {
    const { container } = render(
      <SnackbarItem
        message="Changes saved"
        actions={[{ text: 'Undo', handler: jest.fn() }]}
      />,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when displaying a message and multiple actions', async () => {
    const { container } = render(
      <SnackbarItem
        message="Unable to save file"
        actions={[
          { text: 'Retry', handler: jest.fn() },
          { text: 'Abort', handler: jest.fn() },
        ]}
      />,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render with just a message', () => {
    const { getByRole } = render(
      <SnackbarItem message="File uploaded successfully" />,
    );
    const alertArea = getByRole('alert');

    expect(alertArea.textContent).toEqual('File uploaded successfully');
  });

  it('should render with one action', () => {
    const handler = jest.fn();
    const { getByRole, getByText } = render(
      <SnackbarItem
        message="Changes saved"
        actions={[
          {
            text: 'Undo',
            handler,
          },
        ]}
      />,
    );
    const alertArea = getByRole('alert');

    expect(alertArea.textContent).toEqual('Changes saved');

    const undoButton = getByText('Undo');
    undoButton.click();

    expect(handler).toHaveBeenCalledTimes(1);
  });

  it('should render with multiple actions', () => {
    const retryHandler = jest.fn();
    const abortHandler = jest.fn();

    const { getByRole, getByText } = render(
      <SnackbarItem
        message="Unable to save file"
        actions={[
          { text: 'Retry', handler: retryHandler },
          { text: 'Abort', handler: abortHandler },
        ]}
      />,
    );
    const alertArea = getByRole('alert');

    expect(alertArea.textContent).toEqual('Unable to save file');

    const retryButton = getByText('Retry');
    retryButton.click();

    expect(retryHandler).toHaveBeenCalledTimes(1);

    const abortButton = getByText('Abort');
    abortButton.click();

    expect(abortHandler).toHaveBeenCalledTimes(1);
  });
});
