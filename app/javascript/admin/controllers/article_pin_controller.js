import { Controller } from 'stimulus';

// Handles custom article:pin and article:unpin events
// in Admin -> Content Manager -> Posts
export default class ArticlePinController extends Controller {
  connect() {
    document.addEventListener('article:pin', (event) => {
      console.log(event);
    });

    document.addEventListener('article:unpin', (event) => {
      console.log(event);
    });
  }
}
