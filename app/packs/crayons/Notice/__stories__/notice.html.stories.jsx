import { h } from 'preact';
import '../../storybook-utilities/designSystem.scss';
import notes from './notices.md';

export default {
  title: 'Components/Notices/HTML',
  parameters: { notes },
};

export const Default = () => (
  <div className="crayons-notice">This is Default Notice content.</div>
);

Default.story = {
  name: 'default',
};

export const Danger = () => (
  <div className="crayons-notice crayons-notice--danger">
    This is Default Notice content.
  </div>
);

Danger.story = {
  name: 'danger',
};

export const Warning = () => (
  <div className="crayons-notice crayons-notice--warning">
    This is Warning Notice content.
  </div>
);

Warning.story = {
  name: 'warning',
};

export const Success = () => (
  <div className="crayons-notice crayons-notice--success">
    This is Success Notice content.
  </div>
);

Success.story = {
  name: 'success',
};

export const Info = () => (
  <div className="crayons-notice crayons-notice--info">
    This is Info Notice content.
  </div>
);

Info.story = {
  name: 'info',
};
