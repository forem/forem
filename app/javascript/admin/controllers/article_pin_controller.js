import { Controller } from 'stimulus';

// Handles custom article:pin and article:unpin events
// in Admin -> Content Manager -> Posts
export default class ArticlePinController extends Controller {
  static targets = ['title', 'pinnedAt'];

  connect() {
    document.addEventListener('article:pin', (event) => {
      const { articleId, pinPath } = event.detail;
      this.articlePin({ articleId, pinPath });
    });

    document.addEventListener('article:unpin', (_event) => {});
  }

  async articlePin({ articleId, pinPath }) {
    const response = await fetch(pinPath, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
          .content,
      },
      credentials: 'same-origin',
    });

    if (response.ok) {
      const pinnedArticle = await response.json();

      // only show the modal if we're not re-pinning the current pin
      if (pinnedArticle.id !== articleId) {
        // update the modal's HTML with the data coming from the server
        this.titleTarget.setAttribute('href', pinnedArticle.path);
        this.titleTarget.innerText = pinnedArticle.title;

        this.pinnedAtTarget.setAttribute('datetime', pinnedArticle.pinned_at);
        const time = new Date(pinnedArticle.pinned_at);
        const localizedTime = new Intl.DateTimeFormat('default', {
          dateStyle: 'full',
          timeStyle: 'short',
        }).format(time);
        this.pinnedAtTarget.setAttribute('title', localizedTime);
        this.pinnedAtTarget.textContent = localizedTime;

        // open the modal
        document.dispatchEvent(new CustomEvent('modal:open'));
      }
    }
  }
}
