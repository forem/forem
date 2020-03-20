import { h } from 'preact';

import './designSystem.scss';
import './typography.scss';

export default {
  title: 'Base/Typography/Accent',
};

export const Description = () => (
  <div className="container">
    {' '}
    <h2>Accent typography</h2>
    <p>
      Its main purpose is to add a bit of flavor to DEV brand but it should
      never be the main font.
    </p>
    <p>Please, do not overuse Accent typography.</p>
    <p>
      We strongly encourage to limit number of sizes and weights to what
      presesented below.
    </p>
  </div>
);

Description.story = { name: 'description' };

export const SampleTexts = () => (
  <div>
    {' '}
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
