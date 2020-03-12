import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './designSystem.scss';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

const Fieldset = ({ children }) => (
  <fieldset style={{ border: 'none' }}>{children}</fieldset>
);

Fieldset.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};

storiesOf('Components/HTML/Form Components', module).add('Description', () => (
  <div className="container">
    <h2>Form elements</h2>
    <p>
      Because of accessibility most (ideally all) fields should have label
      above.
    </p>
    <p>
      Fields can also have optional description - between Label and Field
      itself.
    </p>
    <p>
      Fields can also have additional optional description, for example
      characters count.
    </p>
    <h3>Fields with Checkboxes & Radios</h3>
    <p>
      Labels for checkboxes and radios should be placed next to the form
      element.
    </p>
    <p>Using additional description is optional.</p>
    <p>
      It is possible to group checkboxes or radios into logical sections.
      Section may require having it’s own label (title).
    </p>
  </div>
));

storiesOf('Components/HTML/Form Components/Text Field', module)
  .add('Default', () => (
    <input
      type="text"
      className="crayons-textfield"
      placeholder="This is placeholder..."
    />
  ))
  .add('Disabled', () => (
    <input
      type="text"
      className="crayons-textfield"
      placeholder="This is placeholder..."
      value="Disabled field"
      disabled
    />
  ))
  .add('With <label /> and Descriptions', () => (
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
  ));

storiesOf('Components/HTML/Form Components/Multiline Text Field', module)
  .add('Default', () => (
    <textarea
      className="crayons-textfield"
      placeholder="This is placeholder..."
    />
  ))
  .add('Disabled', () => (
    <textarea
      className="crayons-textfield"
      placeholder="This is placeholder..."
      disabled
    >
      Disabled textarea
    </textarea>
  ));

storiesOf('Components/HTML/Form Components/Checkbox', module)
  .add('Default', () => <input type="checkbox" className="crayons-checkbox" />)
  .add('Checked', () => (
    <input type="checkbox" className="crayons-checkbox" checked />
  ))
  .add('Disabled', () => (
    <input type="checkbox" className="crayons-checkbox" disabled />
  ))
  .add('Checked (Disabled)', () => (
    <input type="checkbox" className="crayons-checkbox" checked disabled />
  ))
  .add('Checkbox with <label />', () => (
    <div className="crayons-field crayons-field--checkbox">
      <input type="checkbox" id="c2" className="crayons-checkbox" />
      <label htmlFor="c2" className="crayons-field__label">
        Raspberry
      </label>
    </div>
  ))
  .add('Checkbox with <label /> and Description', () => (
    <div className="crayons-field crayons-field--checkbox">
      <input type="checkbox" id="c2" className="crayons-checkbox" />
      <label htmlFor="c2" className="crayons-field__label">
        Raspberry
        <p className="crayons-field__description">
          This is some description for a textfield lorem ipsum...
        </p>
      </label>
    </div>
  ))
  .add('Checkbox Group', () => (
    <Fieldset>
      <div className="crayons-field crayons-field--checkbox">
        <input
          type="checkbox"
          name="checkboxGroup"
          id="c1"
          className="crayons-checkbox"
        />
        <label htmlFor="c1" className="crayons-field__label">
          Raspberry
        </label>
      </div>
      <div className="crayons-field crayons-field--checkbox">
        <input
          type="checkbox"
          name="checkboxGroup"
          id="c2"
          className="crayons-checkbox"
        />
        <label htmlFor="c2" className="crayons-field__label">
          Strawberry
        </label>
      </div>
      <div className="crayons-field crayons-field--checkbox">
        <input
          type="checkbox"
          name="checkboxGroup"
          id="c3"
          className="crayons-checkbox"
        />
        <label htmlFor="c3" className="crayons-field__label">
          Blueberry
        </label>
      </div>
    </Fieldset>
  ));

storiesOf('Components/HTML/Form Components/Radio Button', module)
  .add('Default', () => (
    <input type="radio" name="n1" className="crayons-radio" />
  ))
  .add('Checked', () => (
    <input type="radio" name="n1" className="crayons-radio" checked />
  ))
  .add('Disabled', () => (
    <input type="radio" name="n2" className="crayons-radio" disabled />
  ))
  .add('Checked (Disabled)', () => (
    <input type="radio" name="n2" className="crayons-radio" checked disabled />
  ))
  .add('With <label />', () => (
    <div className="crayons-field crayons-field--radio">
      <input type="radio" name="name1" id="r2" className="crayons-radio" />
      <label htmlFor="r2" className="crayons-field__label">
        Raspberry
      </label>
    </div>
  ))
  .add('With <label /> and Description', () => (
    <div className="crayons-field crayons-field--radio">
      <input type="radio" name="name1" id="r2" className="crayons-radio" />
      <label htmlFor="r2" className="crayons-field__label">
        Raspberry
        <p className="crayons-field__description">
          This is some description for a textfield lorem ipsum...
        </p>
      </label>
    </div>
  ))
  .add('Radio Button Group', () => (
    <Fieldset>
      <div className="crayons-field crayons-field--radio">
        <input
          type="radio"
          name="radioGroup"
          id="r1"
          className="crayons-radio"
        />
        <label htmlFor="r1" className="crayons-field__label">
          Raspberry
        </label>
      </div>
      <div className="crayons-field crayons-field--radio">
        <input
          type="radio"
          name="radioGroup"
          id="r2"
          className="crayons-radio"
        />
        <label htmlFor="r2" className="crayons-field__label">
          Strawberry
        </label>
      </div>
      <div className="crayons-field crayons-field--radio">
        <input
          type="radio"
          name="radioGroup"
          id="r3"
          className="crayons-radio"
        />
        <label htmlFor="r3" className="crayons-field__label">
          Blueberry
        </label>
      </div>
    </Fieldset>
  ));
