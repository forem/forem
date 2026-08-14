import { h } from 'preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { render, fireEvent } from '@testing-library/preact';
import { CommentCuePopup } from '../CommentCuePopup';

function renderPopup(overrides = {}) {
  const onDismiss = overrides.onDismiss || jest.fn();
  const result = render(
    <CommentCuePopup
      message="Jump in!"
      closeLabel="Dismiss"
      onDismiss={onDismiss}
      {...overrides}
    />,
  );
  return { ...result, onDismiss };
}

function finishLeaveAnimation(container) {
  const popup = container.querySelector('.comment-cue-popup--leaving');
  if (popup) fireEvent.animationEnd(popup);
}

describe('CommentCuePopup', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('renders the popup with the message', () => {
    const { getByText, getByLabelText } = renderPopup();
    expect(getByText('Jump in!')).toBeInTheDocument();
    expect(getByLabelText('Dismiss')).toBeInTheDocument();
  });

  it('has no a11y violations', async () => {
    const { container } = renderPopup();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('calls onDismiss after the leave animation when the close button is clicked', () => {
    const { getByLabelText, container, onDismiss } = renderPopup();
    fireEvent.click(getByLabelText('Dismiss'));
    expect(onDismiss).not.toHaveBeenCalled();
    finishLeaveAnimation(container);
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });

  it('calls onDismiss after the leave animation when Escape is pressed', () => {
    const { container, onDismiss } = renderPopup();
    fireEvent.keyDown(document, { key: 'Escape' });
    expect(onDismiss).not.toHaveBeenCalled();
    finishLeaveAnimation(container);
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });

  it('calls onDismiss after the leave animation on click outside the popup', () => {
    const outside = document.createElement('div');
    document.body.appendChild(outside);
    const { container, onDismiss } = renderPopup();
    fireEvent.mouseDown(outside);
    expect(onDismiss).not.toHaveBeenCalled();
    finishLeaveAnimation(container);
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });
});
