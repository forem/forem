import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components/HTML/Form Components', module).add(
  'Description',
  () => (
    <div className="container">
      <h2>Form elements</h2>
    </div>
  ),
);

storiesOf('Base/Components/HTML/Form Components/Text Field', module)
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
  ));

storiesOf('Base/Components/HTML/Form Components/Multiline Text Field', module)
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

storiesOf('Base/Components/HTML/Form Components/Checkbox', module)
  .add('Default', () => <input type="checkbox" className="crayons-checkbox" />)
  .add('Checked', () => (
    <input type="checkbox" className="crayons-checkbox" checked />
  ))
  .add('Disabled', () => (
    <input type="checkbox" className="crayons-checkbox" disabled />
  ))
  .add('Checked (Disabled)', () => (
    <input type="checkbox" className="crayons-checkbox" checked disabled />
  ));

storiesOf('Base/Components/HTML/Form Components/Radio Button', module)
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
  ));
