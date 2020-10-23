import { h, render } from 'preact';
import { RateLimitModal } from '../rateLimitModal/rateLimitModal'; 

document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('rate-limit-modal');

  render(
    <RateLimitModal 
      title="This is a modal title"
      text="This is the modal body content from a prop"
      className='hidden'
    />
  , root);
});

