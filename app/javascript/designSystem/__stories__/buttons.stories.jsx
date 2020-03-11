import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components', module).add('Buttons', () => (
  <div className="container">
    <div className="body">
      <h2>Buttons</h2>
      <p>
        Use Danger style only for destructive actions like removing something.
        Do not use it for, for example “unfollow” action.
      </p>
      <p>
        If you have to use several buttons together, keep in mind you should
        always have ONE Primary button. Rest of them should be Secondary and/or
        Outlined and/or Text buttons.
      </p>
      <p>
        It is ok to use ONLY Secondary or outlined button without being
        accompanied by Primary one.
      </p>
      <p>
        For Stacking buttons (vertically or horizontally) please use 8px spacing
        unit for default size buttons (no matter if stacking horizontally or
        vertically).
      </p>
    </div>
    <div>
      <a href="#" className="crayons-btn">
        Button label
      </a>
      <br />
      <br />
      <a href="#" className="crayons-btn crayons-btn--full">
        Full Button label
      </a>
      <br />
      <br />
      <a href="#" className="crayons-btn crayons-btn--secondary">
        Secondary Button label
      </a>
      <br />
      <br />
      <a href="#" className="crayons-btn crayons-btn--outlined">
        Outlined Button label
      </a>
      <br />
      <br />
      <a href="#" className="crayons-btn crayons-btn--text">
        Text Button label
      </a>
      <br />
      <br />
      <a href="#" className="crayons-btn crayons-btn--danger">
        Danger Button label
      </a>
      <br />
      <br />
      <a href="#" className="crayons-btn crayons-btn--icon-left">
        <svg
          width="24"
          height="24"
          xmlns="http://www.w3.org/2000/svg"
          className="crayons-icon"
        >
          <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
        </svg>
        Button
      </a>
      <br />
      <br />
      <a
        href="#"
        className="crayons-btn crayons-btn--secondary crayons-btn--full crayons-btn--icon-left"
      >
        <svg
          width="24"
          height="24"
          xmlns="http://www.w3.org/2000/svg"
          className="crayons-icon"
        >
          <path d="M9.99999 15.172L19.192 5.979L20.607 7.393L9.99999 18L3.63599 11.636L5.04999 10.222L9.99999 15.172Z" />
        </svg>
        Button
      </a>
    </div>
  </div>
));
