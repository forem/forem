import { h, render } from 'preact';
import { SearchFormSync } from '../Search/SearchFormSync';

if (document.readyState === "interactive" || document.readyState === "complete") {
  // DOMContentLoaded has already been triggered
  const root = document.getElementById('header-search');

  render(<SearchFormSync />, root);
  window.InstantClick.on('change', () => {
    render(<SearchFormSync />, root);
  });  
} else {
  // Add event listener for DOMContentLoaded
  document.addEventListener("DOMContentLoaded", function () {
    const root = document.getElementById('header-search');

    render(<SearchFormSync />, root);
    window.InstantClick.on('change', () => {
      render(<SearchFormSync />, root);
    });    
  });
}