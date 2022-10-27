import { h } from 'preact';
import notes from './notices.mdx';

export default {
  title: 'Components/Notices',
  parameters: {
    docs: {
      page: notes,
    },
  },
};

export const Default = () => (
  <div className="crayons-notice">This is Default Notice content.</div>
);

Default.storyName = 'default';

export const Danger = () => (
  <div className="crayons-notice crayons-notice--danger">
    This is Default Notice content.
  </div>
);

Danger.storyName = 'danger';

export const Warning = () => (
  <div className="crayons-notice crayons-notice--warning">
    This is Warning Notice content.
  </div>
);

Warning.storyName = 'warning';

export const Success = () => (
  <div className="crayons-notice crayons-notice--success">
    This is Success Notice content.
  </div>
);

Success.storyName = 'success';

export const Info = () => (
  <div className="crayons-notice crayons-notice--info">
    This is Info Notice content.
  </div>
);

Info.storyName = 'info';
