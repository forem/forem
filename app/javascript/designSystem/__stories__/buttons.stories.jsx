import { h } from 'preact';

import './designSystem.scss';

export default {
  title: 'Components/HTML/Buttons',
};

export const Description = () => (
  <div className="container">
    <h2>Buttons</h2>
    <p>
      Use Danger style only for destructive actions like removing something. Do
      not use it for, for example “unfollow” action.
    </p>
    <p>
      If you have to use several buttons together, keep in mind you should
      always have ONE Primary button. Rest of them should be Secondary and/or
      Outlined and/or Text buttons.
    </p>
    <p>
      It is ok to use ONLY Secondary or outlined button without being
      accompanied by Primary one.
    </p>
    <p>
      For Stacking buttons (vertically or horizontally) please use 8px spacing
      unit for default size buttons (no matter if stacking horizontally or
      vertically).
    </p>
  </div>
);

Description.story = {
  name: 'description',
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

export const Text = () => (
  <a href="/" className="crayons-btn crayons-btn--text">
    Text Button label
  </a>
);

Text.story = {
  name: 'story',
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
