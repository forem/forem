import { h } from 'preact';

import '../../storybook-utilities/designSystem.scss';
import './typography.scss';

import notes from './accented-typography.md';

export default {
  title: 'Fundamentals/Typography/2_Accent',
  parameters: {
    notes,
  },
};

export const SampleTexts = () => (
  <div className="sample-texts">
    <div>
      <p className="ff-monospace fs-xs">Lorem ipsum dolor sit amet.</p>
      <p className="ff-monospace fs-s">Lorem ipsum dolor sit amet.</p>
      <p className="ff-monospace fs-base">Lorem ipsum dolor sit amet.</p>
      <p className="ff-monospace fs-l">Lorem ipsum dolor sit amet.</p>
    </div>
    <div>
      <p className="ff-monospace fs-xs fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="ff-monospace fs-s fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="ff-monospace fs-base fw-bold">
        Lorem ipsum dolor sit amet.
      </p>
      <p className="ff-monospace fs-l fw-bold">Lorem ipsum dolor sit amet.</p>
    </div>
  </div>
);

SampleTexts.story = {
  name: 'sample texts',
};
