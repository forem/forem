import { h } from 'preact';

import '../../storybook-utilities/designSystem.scss';
import './typography.scss';

import notes from './accented-typography.md';

export default {
  title: '2_Base/Typography/2_Accent',
  parameters: {
    notes,
  },
};

export const SampleTexts = () => (
  <div className="sample-texts">
    <div>
      <p className="ff-accent fs-xs">Lorem ipsum dolor sit amet.</p>
      <p className="ff-accent fs-s">Lorem ipsum dolor sit amet.</p>
      <p className="ff-accent fs-base">Lorem ipsum dolor sit amet.</p>
      <p className="ff-accent fs-l">Lorem ipsum dolor sit amet.</p>
    </div>
    <div>
      <p className="ff-accent fs-xs fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="ff-accent fs-s fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="ff-accent fs-base fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="ff-accent fs-l fw-bold">Lorem ipsum dolor sit amet.</p>
    </div>
  </div>
);

SampleTexts.story = {
  name: 'sample texts',
};
