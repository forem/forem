import { Controller } from '@hotwired/stimulus';

export class CreatorSettingsController extends Controller {
  updateBranding(event) {
    const color = event.target.value;

    // responsible for accents
    document.documentElement.style.setProperty('--form-border-focus', color);
    // responsible for the help and submit buttons
    document.documentElement.style.setProperty('--button-primary-bg', color);
  }
}
