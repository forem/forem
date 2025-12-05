import { Controller } from '@hotwired/stimulus';

export class ScrollToTopController extends Controller {
  static values = {
    threshold: { type: Number, default: 300 }
  };

  connect() {
    this.toggle();
  }

  toggle() {
    const scrollPosition = window.scrollY || window.pageYOffset;
    
    if (scrollPosition > this.thresholdValue) {
      this.element.classList.remove('hidden');
      this.element.classList.add('visible');
    } else {
      this.element.classList.remove('visible');
      this.element.classList.add('hidden');
    }
  }

  scrollToTop() {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  }
}

export default ScrollToTopController;
