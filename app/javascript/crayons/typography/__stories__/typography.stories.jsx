import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';
import './typography.scss';

export default {
  title: 'Base/Typography/Main',
};

export const Description = () => (
  <div className="container">
    <h2>Main Typography</h2>
    <p>
      Default font is set to 16px (fs-base). It should be standard in UI.
      Smaller and bigger font sizes should be used carefully with respect to
      good visual rythm between elements.
    </p>
    <p>
      XS size should be used as little as possible in edge cases. Even though
      it’s readable we could consider it not meeting DEV’s standards. So keep it
      for like “asterisk copy” etc.
    </p>
    <p>By default you should be using Regular font weight.</p>
    <p>
      Medium should be used to emphasize something but not make it as loud as
      Bold.
    </p>
    <p>Heavy should be used only for bigger title.</p>
  </div>
);

Description.story = {
  name: 'description',
};

export const SampleTexts = () => (
  <div>
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

SampleTexts.story = {
  name: 'sample texts',
};

export const DefaultLineHeight = () => (
  <div>
    <span className="ff-accent">Line height: 1.5 – .lh-base (default)</span>
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

DefaultLineHeight.story = { name: 'default line height' };

export const TightLineHeight = () => (
  <div>
    <span className="ff-accent">Line height: 1.25 – .lh-tight</span>

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

TightLineHeight.story = {
  name: 'tight line height',
};
