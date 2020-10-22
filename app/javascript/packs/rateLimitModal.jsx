import { h, render } from 'preact';
import { RateLimitModal } from '../rateLimitModal/rateLimitModal'; 

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('rate-limit-modal');

  render(
    <RateLimitModal 
      title="This is a modal title"
      className='hidden'
    >
      This is the modal body content
    </RateLimitModal>
  , root);
});

