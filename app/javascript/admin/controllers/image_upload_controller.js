import { Controller } from 'stimulus';

export default class ImageUploadController extends Controller {
  static targets = ['fileField', 'imageResult'];

  onFormSubmit(event) {
    event.preventDefault();
    let token = document.getElementsByName('authenticity_token')[0].value;
    let image = this.fileFieldTarget.files[0];
    let formData = new FormData();

    formData.append('authenticity_token', token);
    formData.append('image', image);

    fetch('/image_uploads', {
      method: 'POST',
      headers: {
        'X-CSRF_Token': window.csrfToken,
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
      });
  }

  onUploadSuccess(result) {
    this.imageResultTarget.classList.remove('d-none');
    const output = `
      <div class="form-group">
        <label for="output">Image URL:</label>
        <textfield id="output" name="output" class="form-control" readonly>
          ${result}
        </textfield>
      </div>
      <img width="300px" src=${result}>
    `;
    this.imageResultTarget.innerHTML = output;
  }
}
