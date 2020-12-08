import { h } from 'preact';
import '../../storybook-utilities/designSystem.scss';
import notes from './modals.md';

export default {
  title: 'Components/Modals/HTML',
  parameters: { notes },
};

export const Default = () => (
  <div className="crayons-modal">
    Hey, I&apos;m a Default Modal content! Lorem ipsum dolor sit amet,
    consectetur adipisicing elit. Sequi ea voluptates quaerat eos consequuntur
    temporibus.
  </div>
);

Default.story = {
  name: 'default',
};

export const Small = () => (
  <div className="crayons-modal crayons-modal--s">
    Hey, I&apos;m a Small Modal content! Lorem ipsum dolor sit amet, consectetur
    adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
  </div>
);

Small.story = {
  name: 'small',
};

export const Large = () => (
  <div className="crayons-modal crayons-modal--l">
    Hey, I&apos;m a Large Modal content! Lorem ipsum dolor sit amet, consectetur
    adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
  </div>
);

Large.story = {
  name: 'large',
};

export const NoPadding = () => (
  <div className="crayons-modal crayons-modal--padding-0">
    Hey, I&apos;m a modal content with no padding! Lorem ipsum dolor sit amet,
    consectetur adipisicing elit. Sequi ea voluptates quaerat eos consequuntur
    temporibus.
  </div>
);

NoPadding.story = {
  name: 'no padding',
};
