import { h } from 'preact';
import { withKnobs, text } from '@storybook/addon-knobs';
import './dropdown-css-helper.scss';
import notes from './dropdowns.md';
import { ButtonNew as Button, Dropdown } from '@crayons';

export default {
  title: 'Components/Dropdowns',
  decorators: [withKnobs],
  parameters: { notes },
};

export const Default = () => (
  <div className="dropdown-trigger-container">
    <Button id="storybook-dropdown-trigger" aria-haspopup="true">
      Click to trigger dropdown
    </Button>
    <Dropdown
      triggerButtonId="storybook-dropdown-trigger"
      dropdownContentId="storybook-dropdown"
      className={text('className', 'mb-2')}
    >
      <p>
        Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
        consectetur adipisicing elit.
      </p>
      <a href="/">Sequi ea voluptates</a>
    </Dropdown>
  </div>
);

Default.story = {
  name: 'default',
};
