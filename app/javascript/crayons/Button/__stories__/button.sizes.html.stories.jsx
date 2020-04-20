import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Buttons/HTML',
};

export const Default = () => (
  <button type="button" className="crayons-btn">
    Button label
  </button>
);

Default.story = {
  name: 'Default',
};

export const Small = () => (
  <button type="button" className="crayons-btn crayons-btn--s">
    Small Button label
  </button>
);

Small.story = {
  name: 'Small',
};

export const Large = () => (
  <button type="button" className="crayons-btn crayons-btn--l">
    Large Button label
  </button>
);

Large.story = {
  name: 'Large',
};

export const XLarge = () => (
  <button type="button" className="crayons-btn crayons-btn--xl">
    Extra Large Button label
  </button>
);

XLarge.story = {
  name: 'Extra Large',
};
