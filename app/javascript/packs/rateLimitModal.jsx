import { h, render } from 'preact';
import { Modal } from '../crayons/Modal'; 

function closeRateLimitModal() {
  if(document.getElementsByClassName('crayons-modal')[0]) {
    document.getElementsByClassName('crayons-modal')[0].classList.add('hidden');
  } 
}

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('rate-limit-modal');

  render(
    <Modal 
      title="This is a modal title"
      className='hidden'
      onClose={closeRateLimitModal}
    >
      This is the modal body content
    </Modal>
  , root);
});

