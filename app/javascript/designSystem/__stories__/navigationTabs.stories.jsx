import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components/Navigation', module).add('Navigation Tabs', () => (
  <div className="container">
    <div className="body">
      <h2>Navigation: Tabs</h2>
      <p>Use tabs as 2nd level navigation or filtering options.</p>
    </div>

    <div>
      <div className="crayons-tabs">
        <a href="#" className="crayons-tabs__item crayons-tabs__item--current">
          Feed
        </a>
        <a href="#" className="crayons-tabs__item">
          Popular
        </a>
        <a href="#" className="crayons-tabs__item">
          Latest
        </a>
      </div>
    </div>
  </div>
));
