import { Controller } from 'stimulus';

export default class ReactionController extends Controller {
  static targets = ['status', 'id', 'reactable'];
}
