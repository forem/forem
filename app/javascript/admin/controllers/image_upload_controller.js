import { Controller } from '@hotwired/stimulus';
import { displayErrorAlert } from '../messageUtilities';

export default class ImageUploadController extends Controller {
  static targets = ['fileField', 'imageResult'];
  static values = { url: String };

  onFormSubmit(event) {
    event.preventDefault();

    const token = document.getElementsByName('authenticity_token')[0].value;
    const image = this.fileFieldTarget.files[0];
    const formData = new FormData();

    formData.append('authenticity_token', token);
    formData.append('image', image);

    fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': window.csrfToken,
      },
      body: formData,
      credentials: 'same-origin',
    })
      .then((response) => response.json())
      .then((json) => {
        if (json.error) {
          throw new Error(json.error);
        }
        const { links } = json;
        return this.onUploadSuccess(links);
      })
      .catch(this.onUploadFailure);
  }

  onUploadSuccess(result) {
    this.imageResultTarget.classList.remove('hidden');
    const output = `
      <div class="mb-4">
        <label for="output" class="crayons-field__label">Image URL:</label>
        <textfield id="output" name="output" class="crayons-textfield" readonly>
          ${result}
        </textfield>
      </div>
      <img width="300px" src=${result}>
    `;
    this.imageResultTarget.innerHTML = output;
  }

  onUploadFailure(error) {
    displayErrorAlert(error.message);
  }
}
