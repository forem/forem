import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Buttons/HTML',
};

export const Default = () => (
  <a href="/" className="crayons-btn">
    Button label
  </a>
);

Default.story = {
  name: 'default',
};

export const Full = () => (
  <a href="/" className="crayons-btn crayons-btn--full">
    Full Button label
  </a>
);

Full.story = {
  name: 'full',
};

export const Secondary = () => (
  <a href="/" className="crayons-btn crayons-btn--secondary">
    Secondary Button label
  </a>
);

Secondary.story = {
  name: 'secondary',
};

export const Outlined = () => (
  <a href="/" className="crayons-btn crayons-btn--outlined">
    Outlined Button label
  </a>
);

Outlined.story = {
  name: 'outlined',
};

export const Danger = () => (
  <a href="/" className="crayons-btn crayons-btn--danger">
    Danger Button label
  </a>
);

Danger.story = {
  name: 'story',
};

export const IconLeft = () => (
  <a href="/" className="crayons-btn crayons-btn--icon-left">
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
    Button
  </a>
);

IconLeft.story = {
  name: 'icon to the left',
};

export const SecondaryFullIconLeft = () => (
  <a
    href="/"
    className="crayons-btn crayons-btn--secondary crayons-btn--full crayons-btn--icon-left"
  >
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
    Button
  </a>
);

SecondaryFullIconLeft.story = {
  name: 'secondary & full & icon to the left',
};
