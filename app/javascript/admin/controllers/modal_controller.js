import { Controller } from 'stimulus';

export default class ModalController extends Controller {
  static values = {
    rootSelector: String,
    contentSelector: String,
    title: String,
    size: String,
  };

  async toggleModal() {
    const [{ Modal }, { render, h }] = await Promise.all([
      import('@crayons/Modal'),
      import('preact'),
    ]);

    const modalRoot = document.querySelector(this.rootSelectorValue);

    render(
      <Modal
        title={this.titleValue}
        onClose={() => {
          render(null, modalRoot);
        }}
        size={this.sizeValue}
      >
        <div
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{
            __html: document.querySelector(this.contentSelectorValue).innerHTML,
          }}
        />
      </Modal>,
      modalRoot,
    );
  }
}
