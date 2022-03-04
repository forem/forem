import { h } from 'preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';
import { MobileDrawer } from '../MobileDrawer';

describe('<MobileDrawer />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <MobileDrawer title="Example MobileDrawer">
        <button>Click me</button>
      </MobileDrawer>,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render correctly', () => {
    const { container } = render(
      <MobileDrawer title="Example MobileDrawer">
        <button>Click me</button>
      </MobileDrawer>,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should trap focus inside the drawer by default', async () => {
    const { getByRole } = render(
      <div>
        <button>Outside drawer button</button>
        <MobileDrawer title="Example MobileDrawer">
          <button>Inside drawer button</button>
          <button>Inside drawer button 2</button>
        </MobileDrawer>
      </div>,
    );

    const innerDrawerButton = getByRole('button', {
      name: 'Inside drawer button',
    });
    await waitFor(() => expect(innerDrawerButton).toHaveFocus());

    userEvent.tab();
    expect(
      getByRole('button', { name: 'Inside drawer button 2' }),
    ).toHaveFocus();

    userEvent.tab();
    expect(innerDrawerButton).toHaveFocus();
  });

  it('should close when Escape is pressed', () => {
    const onClose = jest.fn();
    const { container } = render(
      <MobileDrawer title="Example MobileDrawer" onClose={onClose}>
        <button>Inner button</button>
      </MobileDrawer>,
    );

    userEvent.type(container, '{esc}');
    expect(onClose).toHaveBeenCalled();
  });

  it('should close on click outside', () => {
    const onClose = jest.fn();
    const { getByText } = render(
      <div>
        <p>Outside content</p>
        <MobileDrawer title="Example MobileDrawer" onClose={onClose}>
          <button>Inner button</button>
        </MobileDrawer>
        ,
      </div>,
    );

    userEvent.click(getByText('Outside content'));
    expect(onClose).toHaveBeenCalled();
  });
});
