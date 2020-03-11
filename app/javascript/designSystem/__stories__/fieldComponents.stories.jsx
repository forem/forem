import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components/HTML', module).add('Field Component', () => (
  <div className="container">
    <div className="body">
      <h2>Field Component</h2>
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
    </div>

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

    <pre>
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
    </pre>

    <div className="body">
      <h2>Fields with Checkboxes & Radios</h2>
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

    <div>
      <div className="crayons-field crayons-field--checkbox">
        <input type="checkbox" id="c2" className="crayons-checkbox" />
        <label htmlFor="c2" className="crayons-field__label">
          Raspberry
          <p className="crayons-field__description">
            This is some description for a textfield lorem ipsum...
          </p>
        </label>
      </div>
    </div>

    <div>
      <div className="crayons-fields">
        <div className="crayons-field crayons-field--checkbox">
          <input type="checkbox" id="c3" className="crayons-checkbox" />
          <label htmlFor="c3" className="crayons-field__label">
            Avocado
            <p className="crayons-field__description">
              This is some description for a textfield lorem ipsum...
            </p>
          </label>
        </div>

        <div className="crayons-field crayons-field--checkbox">
          <input type="checkbox" id="c4" className="crayons-checkbox" />
          <label htmlFor="c4" className="crayons-field__label">
            Raspberry
            <p className="crayons-field__description">
              This is some description for a textfield lorem ipsum...
            </p>
          </label>
        </div>

        <div className="crayons-field crayons-field--checkbox">
          <input type="checkbox" id="c5" className="crayons-checkbox" />
          <label htmlFor="c5" className="crayons-field__label">
            Peanut
            <p className="crayons-field__description">
              This is some description for a textfield lorem ipsum...
            </p>
          </label>
        </div>
      </div>
    </div>

    <div>
      <div className="crayons-fields crayons-fields--horizontal">
        <div className="crayons-field crayons-field--checkbox" />
        <input type="checkbox" id="c6" className="crayons-checkbox" />
        <label htmlFor="c6" className="crayons-field__label">
          Avocado
        </label>
      </div>

      <div className="crayons-field crayons-field--checkbox">
        <input type="checkbox" id="c7" className="crayons-checkbox" />
        <label htmlFor="c7" className="crayons-field__label">
          Raspberry
        </label>
      </div>

      <div className="crayons-field crayons-field--checkbox">
        <input type="checkbox" id="c8" className="crayons-checkbox" />
        <label htmlFor="c8" className="crayons-field__label">
          Peanut
        </label>
      </div>
    </div>

    <div>
      <div className="crayons-field crayons-field--radio">
        <input type="radio" name="name1" id="r2" className="crayons-radio" />
        <label htmlFor="r2" className="crayons-field__label">
          Raspberry
          <p className="crayons-field__description">
            This is some description for a textfield lorem ipsum...
          </p>
        </label>
      </div>
    </div>

    <div>
      <div className="crayons-fields">
        <div className="crayons-field crayons-field--radio">
          <input type="radio" name="name2" id="r3" className="crayons-radio" />
          <label htmlFor="r3" className="crayons-field__label">
            Avocado
            <p className="crayons-field__description">
              This is some description for a textfield lorem ipsum...
            </p>
          </label>
        </div>

        <div className="crayons-field crayons-field--radio">
          <input type="radio" name="name2" id="r4" className="crayons-radio" />
          <label htmlFor="r4" className="crayons-field__label">
            Raspberry
            <p className="crayons-field__description">
              This is some description for a textfield lorem ipsum...
            </p>
          </label>
        </div>

        <div className="crayons-field crayons-field--radio">
          <input type="radio" name="name2" id="r5" className="crayons-radio" />
          <label htmlFor="r5" className="crayons-field__label">
            Peanut
            <p className="crayons-field__description">
              This is some description for a textfield lorem ipsum...
            </p>
          </label>
        </div>
      </div>
    </div>

    <div>
      <div className="crayons-fields crayons-fields--horizontal">
        <div className="crayons-field crayons-field--radio">
          <input type="radio" name="name3" id="r6" className="crayons-radio" />
          <label htmlFor="r6" className="crayons-field__label">
            Avocado
          </label>
        </div>

        <div className="crayons-field crayons-field--radio">
          <input type="radio" name="name3" id="r7" className="crayons-radio" />
          <label htmlFor="r7" className="crayons-field__label">
            Raspberry
          </label>
        </div>

        <div className="crayons-field crayons-field--radio">
          <input type="radio" name="name3" id="r8" className="crayons-radio" />
          <label htmlFor="r8" className="crayons-field__label">
            Peanut
          </label>
        </div>
      </div>
    </div>
  </div>
));
