import { h } from 'preact';
import { useState, useRef, useEffect } from 'preact/hooks';
import '../../storybook-utilities/designSystem.scss';
import notes from './dropdowns.md';

export default {
  title: 'Components/Dropdowns/HTML',
  parameters: { notes },
};

const DropdownWithActivator = ({ additionalDropdownClasses = '' }) => {
  const activatorRef = useRef(null);
  const dropdownInteractiveItemRef = useRef(null);
  const [isOpen, setIsOpen] = useState(false);

  const handleActivatorClick = () => {
    setIsOpen(!isOpen);
  };

  const handleKeyUp = (event) => {
    if (event.key === 'Escape' && isOpen) {
      setIsOpen(false);
    }
  };

  const handleClickOutside = (event) => {
    if (
      dropdownInteractiveItemRef.current?.contains(event.target) ||
      activatorRef.current?.contains(event.target)
    ) {
      return;
    }
    setIsOpen(false);
  };

  useEffect(() => {
    if (isOpen) {
      dropdownInteractiveItemRef.current.focus();
      document.addEventListener('mousedown', handleClickOutside);
    } else {
      document.removeEventListener('mousedown', handleClickOutside);
      activatorRef.current.focus();
    }
  }, [isOpen]);

  return (
    // keyUp listener allows dropdown to be closed by keyboard, and is not interactive iteself
    // eslint-disable-next-line jsx-a11y/no-static-element-interactions
    <div className="dropdown-trigger-container" onKeyUp={handleKeyUp}>
      <button
        className="crayons-btn dropdown-trigger"
        aria-haspopup="true"
        aria-expanded={isOpen}
        aria-controls="dropdown-content"
        ref={activatorRef}
        onClick={handleActivatorClick}
      >
        Click to trigger dropdown
      </button>
      <div
        className={`crayons-dropdown ${additionalDropdownClasses} ${
          isOpen ? 'active' : ''
        }`}
        id="dropdown-content"
      >
        <p>
          Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
          consectetur adipisicing elit.
        </p>
        <a href="/" ref={dropdownInteractiveItemRef}>
          Sequi ea voluptates
        </a>
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
