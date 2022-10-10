import { h } from 'preact';

import '../../storybook-utilities/designSystem.scss';
import './typography.scss';

import notes from './typography.mdx';

export default {
  title: 'Fundamentals/Typography/1_Main',
  parameters: { notes },
};

export const SampleTexts = () => (
  <div className="sample-texts">
    <div>
      <p className="fs-xs">Lorem ipsum dolor sit amet.</p>
      <p className="fs-s">Lorem ipsum dolor sit amet.</p>
      <p className="fs-base">Lorem ipsum dolor sit amet.</p>
      <p className="fs-l">Lorem ipsum dolor sit amet.</p>
      <p className="fs-xl">Lorem ipsum dolor sit amet.</p>
      <p className="fs-2xl">Lorem ipsum dolor sit amet.</p>
      <p className="fs-3xl">Lorem ipsum dolor sit amet.</p>
      <p className="fs-4xl">Lorem ipsum dolor sit amet.</p>
      <p className="fs-5xl">Lorem ipsum dolor sit amet.</p>
    </div>

    <div>
      <p className="fs-xs fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-s fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-base fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-l fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-xl fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-2xl fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-3xl fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-4xl fw-medium">Lorem ipsum dolor sit amet.</p>
      <p className="fs-5xl fw-medium">Lorem ipsum dolor sit amet.</p>
    </div>

    <div>
      <p className="fs-xs fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-s fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-base fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-l fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-xl fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-2xl fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-3xl fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-4xl fw-bold">Lorem ipsum dolor sit amet.</p>
      <p className="fs-5xl fw-bold">Lorem ipsum dolor sit amet.</p>
    </div>

    <div>
      <p className="fs-xs fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-s fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-base fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-l fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-xl fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-2xl fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-3xl fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-4xl fw-heavy">Lorem ipsum dolor sit amet.</p>
      <p className="fs-5xl fw-heavy">Lorem ipsum dolor sit amet.</p>
    </div>
  </div>
);

SampleTexts.storyName = 'sample texts';

export const DefaultLineHeight = () => (
  <div className="sample-texts">
    <span className="ff-monospace">Line height: 1.5 – .lh-base (default)</span>
    <h3 className="fs-2xl fw-bold">
      This is a bit longer text title to present line-height difference.
    </h3>
    <p>
      Lorem ipsum dolor sit amet, consectetur adipisicing elit. Labore iusto,
      molestias. Ex asperiores modi libero id laudantium ipsum perspiciatis,
      architecto enim suscipit delectus odit, explicabo quas, voluptatum
      quibusdam, distinctio ut.
    </p>
  </div>
);

DefaultLineHeight.storyName = 'default line height';

export const TightLineHeight = () => (
  <div className="sample-texts">
    <span className="ff-monospace">Line height: 1.25 – .lh-tight</span>

    <h3 className="fs-2xl fw-bold lh-tight">
      This is a bit longer text title to present line-height difference.
    </h3>

    <p className="lh-tight">
      Lorem ipsum dolor sit amet, consectetur adipisicing elit. Labore iusto,
      molestias. Ex asperiores modi libero id laudantium ipsum perspiciatis,
      architecto enim suscipit delectus odit, explicabo quas, voluptatum
      quibusdam, distinctio ut.
    </p>
  </div>
);

TightLineHeight.storyName = 'tight line height';
