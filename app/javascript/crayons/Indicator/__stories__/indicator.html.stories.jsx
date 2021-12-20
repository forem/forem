import { h } from 'preact';
import '../../storybook-utilities/designSystem.scss';
import notes from './indicators.md';

export default {
  title: 'Components/Indicators/HTML',
  parameters: {
    notes,
  },
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
