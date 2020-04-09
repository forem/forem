import { Controller } from 'stimulus';

export default class VomitReactionController extends Controller {
  static targets = ['status'];

  // reactableUserCheck(){
  //   if(this.statusTarget.getAttribute('data-reactable') === 'user'){
  //
  //   }
  // }

  updateReactionStatus() {
    // console.log(`Reaction Status: ${this.statusTarget.value}`);
    // console.log(`Reaction ID: ${this.statusTarget.id}`);
    console.log(`User? ${this.statusTarget.getAttribute('data-id')}`);
  }
}
