import { h } from 'preact';
import { axe } from 'jest-axe';
import { render } from '@testing-library/preact';
import { Modal } from '../Modal';

it('should have no a11y violations', async () => {
  const { container } = render(
    <Modal title="This is a modal title">This is the modal body content</Modal>,
  );
  const results = await axe(container);

  expect(results).toHaveNoViolations();
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

it('should render with additional class names', async () => {
  const { getByTestId } = render(
    <Modal
      title="This is a modal title"
      className={'some-additional-class-name'}
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
      className={'some-additional-class-name'}
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
