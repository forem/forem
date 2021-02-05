import { Controller } from 'stimulus';

// eslint-disable-next-line no-restricted-syntax
export default class ModalController extends Controller {
  static values = {
    contentId: String,
    title: String,
  };

  async toggleModal() {
    const [{ Modal }, { render, h }] = await Promise.all([
      import('@crayons/Modal'),
      import('preact'),
    ]);

    const modalRoot = document.createElement('div');
    document.body.appendChild(modalRoot);

    render(
      <Modal
        title={this.titleValue}
        onClose={() => {
          render(null, modalRoot);
        }}
      >
        <div
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{
            __html: document.querySelector(`#${this.contentIdValue}`).innerHTML,
          }}
        />
      </Modal>,
      modalRoot,
    );
  }
}
