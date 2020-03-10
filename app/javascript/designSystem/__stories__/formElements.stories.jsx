import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components', module).add('Form Components', () => (
  <div className="container">
    <div className="body">
      <h2>Form elements</h2>
    </div>
    <div>
      <input
        type="text"
        className="crayons-textfield"
        placeholder="This is placeholder..."
      />
      <br />
      <br />
      <input
        type="text"
        className="crayons-textfield"
        placeholder="This is placeholder..."
        value="Disabled field"
        disabled
      />
    </div>

    <pre>
      <input
        type="text"
        className="crayons-textfield"
        placeholder="This is placeholder..."
      />
      <input
        type="text"
        className="crayons-textfield"
        placeholder="This is placeholder..."
        value="Disabled field"
        disabled
      />
    </pre>

    <div>
      <textarea
        className="crayons-textfield"
        placeholder="This is placeholder..."
      />
      <br />
      <br />
      <textarea
        className="crayons-textfield"
        placeholder="This is placeholder..."
        disabled
      >
        Disabled textarea
      </textarea>
    </div>

    <pre>
      <textarea
        className="crayons-textfield"
        placeholder="This is placeholder..."
      />
      <textarea
        className="crayons-textfield"
        placeholder="This is placeholder..."
        disabled
      >
        Disabled textarea
      </textarea>
    </pre>

    <div>
      <input type="checkbox" className="crayons-checkbox" />
      <input type="checkbox" className="crayons-checkbox" checked />
      <input type="checkbox" className="crayons-checkbox" disabled />
      <input type="checkbox" className="crayons-checkbox" checked disabled />
    </div>

    <pre>
      <input type="checkbox" className="crayons-checkbox" />
      <input type="checkbox" className="crayons-checkbox" checked />
      <input type="checkbox" className="crayons-checkbox" disabled />
      <input type="checkbox" className="crayons-checkbox" checked disabled />
    </pre>

    <div>
      <input type="radio" name="n1" className="crayons-radio" />
      <input type="radio" name="n1" className="crayons-radio" checked />
      <input type="radio" name="n2" className="crayons-radio" disabled />
      <input
        type="radio"
        name="n2"
        className="crayons-radio"
        checked
        disabled
      />
    </div>

    <pre>
      <input type="radio" name="n1" className="crayons-radio" />
      <input type="radio" name="n1" className="crayons-radio" checked />
      <input type="radio" name="n2" className="crayons-radio" disabled />
      <input
        type="radio"
        name="n2"
        className="crayons-radio"
        checked
        disabled
      />
    </pre>
  </div>
));
