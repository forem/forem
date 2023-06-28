import { h } from 'preact';
import './dropdown-css-helper.scss';
import notes from './dropdowns.mdx';
import { Dropdown, ButtonNew as Button } from '@crayons';

export default {
  title: 'Components/Dropdowns',
  parameters: {
    docs: {
      page: notes,
    },
  },
};

export const Default = () => (
  <div className="dropdown-trigger-container">
    <Button
      id="storybook-dropdown-trigger"
      className="dropdown-trigger"
      aria-haspopup="true"
    >
      Click to trigger dropdown
    </Button>
    <Dropdown
      triggerButtonId="storybook-dropdown-trigger"
      dropdownContentId="storybook-dropdown"
    >
      <p>
        Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
        consectetur adipisicing elit.
      </p>
      <a href="/">Sequi ea voluptates</a>
    </Dropdown>
  </div>
);

Default.storyName = 'default';
