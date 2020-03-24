import { h } from 'preact';

import './designSystem.scss';

export default {
  title: 'Components/HTML/Indicators',
};

export const Description = () => (
  <div className="container">
    <h2>Indicators</h2>
    <p>
      Indicators are meant to be used to inform user about, for example, unread
      notifications. They supposed to steal user&apos;s attention and make him
      notice or click specific element.
    </p>
    <p>
      We should keep in mind to never show too many indicators at the same time.
      Use your best judgment.
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
);

Description.story = {
  name: 'description',
};

export const Default = () => <span className="crayons-indicator">Label</span>;
Default.story = { name: 'default (grey)' };

export const GreyOutlined = () => (
  <span className="crayons-indicator crayons-indicator--outlined">
    Outlined
  </span>
);

GreyOutlined.story = {
  name: 'grey outlined',
};

export const GreyWithNumber = () => (
  <span className="crayons-indicator">1</span>
);

GreyWithNumber.story = {
  name: 'grey with number',
};

export const GreyBullet = () => (
  <span className="crayons-indicator crayons-indicator--bullet" />
);

GreyBullet.story = { name: 'grey bullet' };

export const Accent = () => (
  <span className="crayons-indicator crayons-indicator--accent">Label</span>
);

Accent.story = {
  name: 'accent',
};

export const AccentOutlined = () => (
  <span className="crayons-indicator crayons-indicator--outlined crayons-indicator--accent">
    Outlined
  </span>
);

AccentOutlined.story = { name: 'accent outlined' };

export const AccentWithNumber = () => (
  <span className="crayons-indicator crayons-indicator--accent">1</span>
);

AccentWithNumber.story = {
  name: 'accent with number',
};

export const AccentBullet = () => (
  <span className="crayons-indicator crayons-indicator--accent crayons-indicator--bullet" />
);

AccentBullet.story = { name: 'accent bullet' };

export const Critical = () => (
  <span className="crayons-indicator crayons-indicator--critical">Label</span>
);

Critical.story = {
  name: 'critical',
};

export const CriticalOutline = () => (
  <span className="crayons-indicator crayons-indicator--outlined crayons-indicator--critical">
    Outlined
  </span>
);

CriticalOutline.story = {
  name: 'critical outline',
};

export const CriticalWithNumber = () => (
  <span className="crayons-indicator crayons-indicator--critical">1</span>
);

CriticalWithNumber.story = {
  name: 'critical with number',
};

export const CriticalWithBullet = () => (
  <span className="crayons-indicator crayons-indicator--critical crayons-indicator--bullet" />
);

CriticalWithBullet.story = {
  name: 'critical bullet',
};

export const Inverted = () => (
  <span className="crayons-indicator crayons-indicator--inverted">Label</span>
);

Inverted.story = { name: 'inverted' };

export const InvertedOutlined = () => (
  <span className="crayons-indicator crayons-indicator--outlined crayons-indicator--inverted">
    Outlined
  </span>
);

InvertedOutlined.story = {
  name: 'inverted outlined',
};

export const InvertedWithNumber = () => (
  <span className="crayons-indicator crayons-indicator--inverted">1</span>
);

InvertedWithNumber.story = {
  name: 'inverted with number',
};

export const InvertedBullet = () => (
  <span className="crayons-indicator crayons-indicator--inverted crayons-indicator--bullet" />
);

InvertedBullet.story = { name: 'inverted bullet' };
