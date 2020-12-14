import { h } from 'preact';

import '../../../storybook-utilities/designSystem.scss';

export default { title: 'Components/Form Components/Text Field/HTML' };

export const Default = () => (
  <input
    type="text"
    className="crayons-textfield"
    placeholder="This is placeholder..."
  />
);

Default.story = { name: 'default' };

export const Disabled = () => (
  <input
    type="text"
    className="crayons-textfield"
    placeholder="This is placeholder..."
    value="Disabled field"
    disabled
  />
);

Disabled.story = { name: 'disabled' };

export const WithLabelAndDescriptions = () => (
  <div className="crayons-field">
    <label htmlFor="t1" className="crayons-field__label">
      Textfield Label
      <p className="crayons-field__description">
        This is some description for a textfield lorem ipsum...
      </p>
    </label>
    <input
      type="text"
      id="t1"
      className="crayons-textfield"
      placeholder="This is placeholder..."
    />
    <p className="crayons-field__description">
      Another description just in case...
    </p>
  </div>
);

WithLabelAndDescriptions.story = {
  name: 'with <label /> and descriptions',
};
