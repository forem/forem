import { h } from 'preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';
import { Modal } from '../Modal';

it('should have no a11y violations', async () => {
  const { container } = render(
    <Modal title="This is a modal title">This is the modal body content</Modal>,
  );
  const results = await axe(container);

  expect(results).toHaveNoViolations();
});

it('should trap focus inside the modal by default', async () => {
  const { getByText, getByLabelText } = render(
    <div>
      <button>Outside modal button</button>
      <Modal title="This is a modal title">
        <button>Modal content button</button>
      </Modal>
    </div>,
  );

  const closeButton = getByLabelText('Close', { selector: 'button' });
  await waitFor(() => expect(closeButton).toHaveFocus());

  userEvent.tab();
  expect(getByText('Modal content button')).toHaveFocus();

  userEvent.tab();
  expect(closeButton).toHaveFocus();
});

it('should trap focus in the custom selector if provided in props', async () => {
  const { getByText } = render(
    <div>
      <button>Outside modal button</button>
      <Modal title="This is a modal title" focusTrapSelector="#trap-focus-here">
        <button>Outside focus trap button</button>
        <div id="trap-focus-here">
          <button>Inside focus trap button</button>
        </div>
      </Modal>
    </div>,
  );

  const buttonInsideFocusTrap = getByText('Inside focus trap button');
  await waitFor(() => expect(buttonInsideFocusTrap).toHaveFocus());
});

it('should close when the close button is clicked', async () => {
  const onClose = jest.fn();
  const { getByLabelText } = render(
    <Modal title="This is a modal title" onClose={onClose}>
      This is the modal body content
    </Modal>,
  );

  const closeButton = getByLabelText('Close', { selector: 'button' });

  closeButton.click();

  expect(onClose).toHaveBeenCalledTimes(1);
});

it('should close when Escape is pressed', () => {
  const onClose = jest.fn();
  const { container } = render(
    <Modal title="This is a modal title" onClose={onClose}>
      This is the modal body content
    </Modal>,
  );

  userEvent.type(container, '{esc}');
  expect(onClose).toHaveBeenCalledTimes(1);
});

it("shouldn't close on outside click by default", () => {
  const onClose = jest.fn();
  const { getByText } = render(
    <div>
      <p>Outside content</p>
      <Modal title="This is a modal title" onClose={onClose}>
        This is the modal body content
      </Modal>
    </div>,
  );

  userEvent.click(getByText('Outside content'));
  expect(onClose).not.toHaveBeenCalled();
});

it('should close on click outside, if enabled', () => {
  const onClose = jest.fn();
  const { getByText } = render(
    <div>
      <p>Outside content</p>
      <Modal
        title="This is a modal title"
        onClose={onClose}
        closeOnClickOutside
      >
        This is the modal body content
      </Modal>
    </div>,
  );

  userEvent.click(getByText('Outside content'));
  expect(onClose).toHaveBeenCalledTimes(1);
});

it('should render with additional class names', async () => {
  const { getByTestId } = render(
    <Modal
      title="This is a modal title"
      className="some-additional-class-name"
      onClose={jest.fn()}
    >
      This is the modal body content
    </Modal>,
  );

  const modalContainer = getByTestId('modal-container');

  expect(
    modalContainer.classList.contains('some-additional-class-name'),
  ).toEqual(true);
});

it('should render with an overlay', async () => {
  const { getByTestId } = render(
    <Modal title="This is a modal title" overlay onClose={jest.fn()}>
      This is the modal body content
    </Modal>,
  );

  const modalOverlay = getByTestId('modal-overlay');

  expect(modalOverlay).not.toBeNull();
});

it('should render with a different size modal', async () => {
  const { getByTestId } = render(
    <Modal
      title="This is a modal title"
      size="large"
      className="some-additional-class-name"
      onClose={jest.fn()}
    >
      This is the modal body content
    </Modal>,
  );

  const modalContainer = getByTestId('modal-container');

  expect(modalContainer.classList.contains('crayons-modal--large')).toEqual(
    true,
  );
});
