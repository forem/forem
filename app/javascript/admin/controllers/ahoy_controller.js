import { Controller } from 'stimulus';
import ahoy from 'ahoy.js';

ahoy.configure({
  cookies: false,
  trackVisits: false,
});

// eslint-disable-next-line no-restricted-syntax
export default class AhoyController extends Controller {
  trackOverviewLink(event) {
    event.preventDefault();
    let properties = {
      action: event.type,
      target: event.target.toString(),
    };
    ahoy.track('Admin Overview Link Clicked', properties);
    window.location.href = event.target.href;
  }
}
