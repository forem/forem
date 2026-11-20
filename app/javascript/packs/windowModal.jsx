import { h, render } from 'preact';
import { Modal } from '@crayons';
import { WINDOW_MODAL_ID } from '@utilities/windowModalLoader';

export function renderWindowModal({
  modalContent,
  contentSelector,
  onOpen,
  document = window.document,
  ...modalProps
}) {
  // Guard against two modals being opened at once
  let currentModalContainer = document.getElementById(WINDOW_MODAL_ID);
  if (currentModalContainer) {
    render(null, currentModalContainer);
  } else {
    currentModalContainer = document.createElement('div');
    currentModalContainer.setAttribute('id', WINDOW_MODAL_ID);
    document.body.appendChild(currentModalContainer);
  }

  render(
    <Modal
      onClose={() => {
        render(null, currentModalContainer);
      }}
      focusTrapSelector={`#${WINDOW_MODAL_ID}`}
      document={document}
      {...modalProps}
    >
      <div
        className="h-100 w-100"
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html:
            modalContent ?? document.querySelector(contentSelector)?.innerHTML,
        }}
      />
    </Modal>,
    currentModalContainer,
  );

  onOpen?.();
}

export function unmountWindowModal(document = window.document) {
  const currentModalContainer = document.getElementById(WINDOW_MODAL_ID);
  if (currentModalContainer) {
    render(null, currentModalContainer);
  }
}

if (typeof window !== 'undefined') {
  window.Forem = window.Forem || {};
  window.Forem.renderWindowModal = renderWindowModal;
  window.Forem.unmountWindowModal = unmountWindowModal;
}
