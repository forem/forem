import { Controller } from '@hotwired/stimulus';
import ahoy from 'ahoy.js';

ahoy.configure({
  cookies: false,
  trackVisits: false,
});

export default class AhoyController extends Controller {
  trackOverviewLink(event) {
    event.preventDefault();
    const properties = {
      action: event.type,
      target: event.target.toString(),
    };
    ahoy.track('Admin Overview Link Clicked', properties);
    window.location.href = event.target.href;
  }
}
