import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components', module).add('Indicators', () => (
  <div className="container">
    <div className="body">
      <h2>Indicators</h2>
      <p>
        Indicators are meant to be used to inform user about, for example,
        unread notifications. They supposed to steal user&apos;s attention and
        make him notice or click specific element.
      </p>
      <p>
        We should keep in mind to never show too many indicators at the same
        time. Use your best judgment.
      </p>
      <p>There&apos;re two types of indicators:</p>
      <ul>
        <li>Rectangle with label (text or number)</li>
        <li>Bullet - just a circle without any text on it.</li>
      </ul>
      <p>And there&apos;re four styles to pick from:</p>
      <ul>
        <li>
          Default (grey) - nothing really crucial, basic information about
          something.
        </li>
        <li>
          Accent (blueish) - something we want user to be aware of but it&apos;s
          also not crucial information
        </li>
        <li>
          Critical (red) - something super important, don&apos;t overuse it!!
        </li>
        <li>
          Inverted (dark grey) - alternative to the default one, especially when
          we need to show two defautl indicators next to each other.
        </li>
      </ul>
    </div>
    <div>
      <span className="crayons-indicator">Label</span>
      <span className="crayons-indicator crayons-indicator--outlined">
        Outlined
      </span>
      <span className="crayons-indicator">1</span>
      <span className="crayons-indicator crayons-indicator--bullet" />
    </div>

    <div>
      <span className="crayons-indicator crayons-indicator--accent">Label</span>
      <span className="crayons-indicator crayons-indicator--outlined crayons-indicator--accent">
        Outlined
      </span>
      <span className="crayons-indicator crayons-indicator--accent">1</span>
      <span className="crayons-indicator crayons-indicator--accent crayons-indicator--bullet" />
    </div>

    <div>
      <span className="crayons-indicator crayons-indicator--critical">
        Label
      </span>
      <span className="crayons-indicator crayons-indicator--outlined crayons-indicator--critical">
        Outlined
      </span>
      <span className="crayons-indicator crayons-indicator--critical">1</span>
      <span className="crayons-indicator crayons-indicator--critical crayons-indicator--bullet" />
    </div>

    <div>
      <span className="crayons-indicator crayons-indicator--inverted">
        Label
      </span>
      <span className="crayons-indicator crayons-indicator--outlined crayons-indicator--inverted">
        Outlined
      </span>
      <span className="crayons-indicator crayons-indicator--inverted">1</span>
      <span className="crayons-indicator crayons-indicator--inverted crayons-indicator--bullet" />
    </div>
  </div>
));
