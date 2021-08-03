import { h } from 'preact';
import { withKnobs, text } from '@storybook/addon-knobs';
import './dropdown-css-helper.scss';
import notes from './dropdowns.md';
import { Dropdown } from '@crayons';

export default {
  title: 'Components/Dropdowns',
  decorators: [withKnobs],
  parameters: { notes },
};

const DropdownWithActivator = ({ additionalDropdownClasses }) => {
  return (
    <div className="dropdown-trigger-container">
      <button
        id="storybook-dropdown-trigger"
        className="crayons-btn dropdown-trigger"
        aria-haspopup="true"
      >
        Click to trigger dropdown
      </button>
      <Dropdown
        triggerButtonId="storybook-dropdown-trigger"
        dropdownContentId="storybook-dropdown"
        className={additionalDropdownClasses}
      >
        <p>
          Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
          consectetur adipisicing elit.
        </p>
        <a href="/">Sequi ea voluptates</a>
      </Dropdown>
    </div>
  );
};

export const Default = () => (
  <DropdownWithActivator
    additionalDropdownClasses={text('className', 'mb-2')}
  />
);

Default.story = {
  name: 'default',
};

export const AdditonalCssClasses = () => (
  <DropdownWithActivator additionalDropdownClasses={text('className', 'p-6')} />
);

AdditonalCssClasses.story = {
  name: 'additional CSS classes',
};
