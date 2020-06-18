import { h } from 'preact';

export const Spinner = () => (
  <svg
    className="crayons-spinner"
    width="18px"
    height="18px"
    viewBox="0 0 18 18"
    aria-hidden="true"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M15.364 2.636L13.95 4.05A7 7 0 1016 9h2a9 9 0 11-2.636-6.364z"
      fill="currentColor"
    />
  </svg>
);
