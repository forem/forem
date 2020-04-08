import { h } from 'preact';

export const OverflowNavigation = () => {
	return (
	  <button className="crayons-btn crayons-btn--ghost crayons-story__overflow" type="button">
	    <svg className="crayons-icon" width="24" height="24" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M7 12a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0zm5 2a2 2 0 100-4 2 2 0 000 4z"/></svg>
	  </button>
	);
};

OverflowNavigation.displayName = 'OverflowNavigation';
