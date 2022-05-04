// Unique ID applied to modals created using the showWindowModal function
const WINDOW_MODAL_ID = 'window-modal';

// We only import these modules if a user actually triggers a modal. Here we cache them so they are only imported once.
let preactImport;
let modalImports;

const getPreactImport = () => {
  if (!preactImport) {
    preactImport = import('preact');
  }
  return preactImport;
};

const getModalImports = () => {
  if (!modalImports) {
    modalImports = [import('@crayons/Modal'), getPreactImport()];
  }
  return Promise.all(modalImports);
};

/**
 * This helper function finds the HTML with the given contentSelector, and presents it inside a Preact modal.
 * Only one modal will be presented at any given time.
 *
 * @param {Object} args
 * @param {string} args.title The title of the modal (presented at the top of the modal dialog)
 * @param {string} args.contentSelector The CSS query to locate the HTML to be presented in the modal (e.g. '#my-modal-content')
 * @param {string} args.size The size prop for the modal ('small', 'medium', or 'large')
 * @param {Function} args.onOpen A callback function to run when the modal opens. This can be useful, for example, to attach any event listeners to items inside the modal.
 */
export const showWindowModal = async ({
  title,
  contentSelector,
  size = 'small',
  onOpen,
}) => {
  const [{ Modal }, { render, h }] = await getModalImports();

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
      title={title}
      onClose={() => {
        render(null, currentModalContainer);
      }}
      size={size}
      focusTrapSelector={`#${WINDOW_MODAL_ID}`}
    >
      <div
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: document.querySelector(contentSelector).innerHTML,
        }}
      />
    </Modal>,
    currentModalContainer,
  );

  onOpen?.();
};

/**
 * This helper function closes any currently open window modal. This can be useful, for example, if your modal contains a "cancel" button.
 */
export const closeWindowModal = async () => {
  const currentModalContainer = document.getElementById(WINDOW_MODAL_ID);
  if (currentModalContainer) {
    const { render } = await getPreactImport();
    render(null, currentModalContainer);
  }
};
