import { h } from 'preact';
import { useLayoutEffect } from 'preact/hooks';
import notes from './dropdowns.md';
import { initializeDropdown } from '@utilities/dropdownUtils';
import '../../storybook-utilities/designSystem.scss';

export default {
  title: 'Components/Dropdowns/HTML',
  parameters: { notes },
};

const DropdownWithActivator = ({ additionalDropdownClasses = '' }) => {
  useLayoutEffect(() => {
    initializeDropdown({
      triggerElementId: 'storybook-dropdown-trigger',
      dropdownContentId: 'storybook-dropdown',
    });
  }, []);

  return (
    <div className="dropdown-trigger-container">
      <button
        id="storybook-dropdown-trigger"
        className="crayons-btn dropdown-trigger"
      >
        Click to trigger dropdown
      </button>
      <div
        id="storybook-dropdown"
        className={`crayons-dropdown ${additionalDropdownClasses}`}
      >
        <p>
          Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
          consectetur adipisicing elit.
        </p>
        <a href="/">Sequi ea voluptates</a>
      </div>
    </div>
  );
};

export const Default = () => <DropdownWithActivator />;

Default.story = {
  name: 'default',
};

export const AdditonalCssClasses = () => (
  <DropdownWithActivator additionalDropdownClasses="p-6" />
);

AdditonalCssClasses.story = {
  name: 'additional CSS classes',
};
