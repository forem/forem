import { h } from 'preact';
import render from 'preact-render-to-json';
import { Snackbar, SnackbarItem } from '..';

describe('<Snackbar />', () => {
  it('should render with one snackbar item', () => {
    const tree = render(
      <Snackbar>
        <SnackbarItem message="File uploaded successfully" />
      </Snackbar>,
    );

    expect(tree).toMatchSnapshot();
  });

  it('should render with multiple snackbar items', () => {
    const snackbarItems = [
      {
        message: 'File uploaded successfully',
      },

      {
        message: 'Unable to save file',
        actions: [
          { text: 'Retry', handler: jest.fn() },
          { text: 'Abort', handler: jest.fn() },
        ],
      },

      {
        message: 'There was a network error',
        actions: [{ text: 'Retry', handler: jest.fn() }],
      },
    ];

    const tree = render(
      <Snackbar>
        {snackbarItems.map(({ message, actions = [] }) => (
          <SnackbarItem message={message} actions={actions} />
        ))}
      </Snackbar>,
    );

    expect(tree).toMatchSnapshot();
  });
});
