import { h } from 'preact';
import { useState, useRef, useEffect } from 'preact/hooks';
import { withKnobs, text } from '@storybook/addon-knobs';
import './dropdown-css-helper.scss';
import notes from './dropdowns.md';
import { Dropdown } from '@crayons';

export default {
  title: 'Components/Dropdowns',
  decorators: [withKnobs],
  parameters: { notes },
};

export const Default = () => {
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
        aria-controls="dropdown-content"
        ref={activatorRef}
        onClick={handleActivatorClick}
      >
        Click to trigger dropdown
      </button>
      <Dropdown
        className={`${text('className', 'mb-2')} ${isOpen ? 'active' : ''}`}
        id="dropdown-content"
      >
        <p>
          Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
          consectetur adipisicing elit.
        </p>
        <a href="/" ref={dropdownInteractiveItemRef}>
          Sequi ea voluptates
        </a>
      </Dropdown>
    </div>
  );
};

Default.story = {
  name: 'default',
};

export const AdditonalCssClasses = () => {
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
        aria-controls="dropdown-content"
        ref={activatorRef}
        onClick={handleActivatorClick}
      >
        Click to trigger dropdown
      </button>
      <Dropdown
        className={`${text('className', 'p-6')} ${isOpen ? 'active' : ''}`}
        id="dropdown-content"
      >
        <p>
          Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet,
          consectetur adipisicing elit.
        </p>
        <a href="/" ref={dropdownInteractiveItemRef}>
          Sequi ea voluptates
        </a>
      </Dropdown>
    </div>
  );
};

AdditonalCssClasses.story = {
  name: 'additional CSS classes',
};
