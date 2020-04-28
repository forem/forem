import { h } from 'preact';
import render from 'preact-render-to-json';
import { SnackbarItem } from '..';

describe('<SnackbarItem />', () => {
  it('should render with just a message', () => {
    const tree = render(<SnackbarItem message="File uploaded successfully" />);

    expect(tree).toMatchSnapshot();
  });

  it('should render with one action', () => {
    const tree = render(
      <SnackbarItem
        message="Changes saved"
        actions={[{ text: 'Undo', handler: jest.fn() }]}
      />,
    );

    expect(tree).toMatchSnapshot();
  });

  it('should render with multiple actions', () => {
    const tree = render(
      <SnackbarItem
        message="Unable to save file"
        actions={[
          { text: 'Retry', handler: jest.fn() },
          { text: 'Abort', handler: jest.fn() },
        ]}
      />,
    );

    expect(tree).toMatchSnapshot();
  });
});
