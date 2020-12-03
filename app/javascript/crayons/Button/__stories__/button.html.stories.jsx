import { h } from 'preact';
import '../../storybook-utilities/designSystem.scss';
import notes from './buttons.md';

export default {
  title: 'Components/Buttons/HTML',
  parameters: {
    notes,
  },
};

export const Primary = () => (
  <button type="button" className="crayons-btn">
    Button label
  </button>
);

Primary.story = {
  name: 'primary',
};

export const Secondary = () => (
  <button type="button" className="crayons-btn crayons-btn--secondary">
    Secondary Button label
  </button>
);

Secondary.story = {
  name: 'Secondary',
};

export const Outlined = () => (
  <button type="button" className="crayons-btn crayons-btn--outlined">
    Outlined Button label
  </button>
);

Outlined.story = {
  name: 'Outlined',
};

export const Danger = () => (
  <button type="button" className="crayons-btn crayons-btn--danger">
    Danger Button label
  </button>
);

Danger.story = {
  name: 'Danger',
};

export const Ghost = () => (
  <button type="button" className="crayons-btn crayons-btn--ghost">
    Ghost Button label
  </button>
);

Ghost.story = {
  name: 'Ghost',
};

export const GhostDimmed = () => (
  <button type="button" className="crayons-btn crayons-btn--ghost-dimmed">
    Ghost Dimmed Button label
  </button>
);

Ghost.story = {
  name: 'Ghost Dimmed',
};

export const GhostBrand = () => (
  <button type="button" className="crayons-btn crayons-btn--ghost-brand">
    Ghost Brand Button label
  </button>
);

GhostBrand.story = {
  name: 'Ghost Brand',
};

export const GhostSuccess = () => (
  <button type="button" className="crayons-btn crayons-btn--ghost-success">
    Ghost Success Button label
  </button>
);

GhostSuccess.story = {
  name: 'Ghost Success',
};

export const GhostWarning = () => (
  <button type="button" className="crayons-btn crayons-btn--ghost-warning">
    Ghost Warning Button label
  </button>
);

GhostWarning.story = {
  name: 'Ghost Warning',
};

export const GhostDanger = () => (
  <button type="button" className="crayons-btn crayons-btn--ghost-danger">
    Ghost Danger Button label
  </button>
);

GhostDanger.story = {
  name: 'Ghost Danger',
};

export const IconLeft = () => (
  <button type="button" className="crayons-btn crayons-btn--icon-left">
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
    Button
  </button>
);

IconLeft.story = {
  name: 'Icon to the left',
};

export const IconRight = () => (
  <button type="button" className="crayons-btn crayons-btn--icon-right">
    Button
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
  </button>
);

IconRight.story = {
  name: 'Icon to the right',
};

export const IconAlone = () => (
  <button type="button" className="crayons-btn crayons-btn--icon">
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
  </button>
);

IconAlone.story = {
  name: 'Icon alone',
};

export const IconRounded = () => (
  <button type="button" className="crayons-btn crayons-btn--icon-rounded">
    <svg
      width="24"
      height="24"
      xmlns="http://www.w3.org/2000/svg"
      className="crayons-icon"
    >
      <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
    </svg>
  </button>
);

IconRounded.story = {
  name: 'Icon rounded',
};
