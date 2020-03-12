import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './designSystem.scss';
import './typography.scss';

storiesOf('Base/Typography/Main', module)
  .add('Description', () => (
    <div className="container">
      <h2>Main Typography</h2>
      <p>
        Default font is set to 16px (fs-base). It should be standard in UI.
        Smaller and bigger font sizes should be used carefully with respect to
        good visual rythm between elements.
      </p>
      <p>
        XS size should be used as little as possible in edge cases. Even though
        it’s readable we could consider it not meeting DEV’s standards. So keep
        it for like “asterisk copy” etc.
      </p>
      <p>By default you should be using Regular font weight.</p>
      <p>
        Medium should be used to emphasize something but not make it as loud as
        Bold.
      </p>
      <p>Heavy should be used only for bigger title.</p>
    </div>
  ))
  .add('Sample Texts', () => (
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
  ))
  .add('Default Line Height', () => (
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
  ))
  .add('Tight Line Height', () => (
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
  ));

storiesOf('Base/Typography/Accent', module)
  .add('Description', () => (
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
  ))
  .add('Sample Texts', () => (
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
  ));
