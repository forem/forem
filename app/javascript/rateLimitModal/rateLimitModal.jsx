import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Modal } from '../crayons/Modal'

export class RateLimitModal extends Component {
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
        {this.props.text}
      </Modal>
    )
  }

}

RateLimitModal.propTypes = {
  text: PropTypes.arrayOf(PropTypes.string).isRequired,
};
