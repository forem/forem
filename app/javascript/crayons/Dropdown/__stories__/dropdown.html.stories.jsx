import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Dropdowns/HTML',
};

export const Default = () => (
  <div className="crayons-dropdown" style={{ display: 'block' }}>
    Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
    adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
  </div>
);

Default.story = {
  name: 'default',
};

export const Large = () => (
  <div
    className="crayons-dropdown crayons-dropdown--l"
    style={{ display: 'block' }}
  >
    Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
    adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
  </div>
);

Large.story = {
  name: 'large',
};
