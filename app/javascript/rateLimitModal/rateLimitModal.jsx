import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Modal } from '../crayons/Modal'

export class RateLimitModal extends Component {

  constructor() {
    super();
    this.state = { };
  }

  closeRateLimitModal = () => {
    if(document.getElementsByClassName('crayons-modal')[0]) {
      document.getElementsByClassName('crayons-modal')[0].classList.add('hidden');
    } 
  }

  render() {
    return (
      <Modal 
        title="This is a rate limit modal title"
        className='hidden'
        onClose={this.closeRateLimitModal}
      >
        This is the rate limit modal body content
      </Modal>
    )
  }

}
