import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components', module).add('Avatars & Logos', () => (
  <div className="container">
    <div className="body">
      <h2>Avatars &amp; Logos</h2>
      <p>An image representing a user is called an avatar.</p>
      <p>An image representing a company or organization is called a logo.</p>
      <p>
        To make a distinction between these two different entities we should
        keep them visually different. For Avatars, we gonna use circle shape.
        And for Logos we gonna use square shape. This will help recognize what
        is what in a heartbeat.
      </p>
      <p>
        Each of these will be available in 5 different sizes (use your best
        judgment in picking right size):
      </p>
      <ul>
        <li>Default: 24px</li>
        <li>L(arge): 32px</li>
        <li>XL(arge): 48px</li>
        <li>2XL(arge): 64px</li>
        <li>3XL(arge): 128px</li>
      </ul>
      <p>Remember to use descriptive alt="" values!</p>
    </div>
    <div>
      <span className="crayons-avatar">
        <img
          src="/images/ben.jpg"
          className="crayons-avatar__image"
          alt="Ben"
        />
      </span>
      <span className="crayons-avatar crayons-avatar--l">
        <img
          src="/images/ben.jpg"
          className="crayons-avatar__image"
          alt="Ben"
        />
      </span>
      <span className="crayons-avatar crayons-avatar--xl">
        <img
          src="/images/ben.jpg"
          className="crayons-avatar__image"
          alt="Ben"
        />
      </span>
      <span className="crayons-avatar crayons-avatar--2xl">
        <img
          src="/images/ben.jpg"
          className="crayons-avatar__image"
          alt="Ben"
        />
      </span>
      <span className="crayons-avatar crayons-avatar--3xl">
        <img
          src="/images/ben.jpg"
          className="crayons-avatar__image"
          alt="Ben"
        />
      </span>
    </div>

    <div>
      <span className="crayons-logo">
        <img
          src="/images/apple-icon.png"
          className="crayons-logo__image"
          alt="Acme Inc."
        />
      </span>
      <span className="crayons-logo crayons-logo--l">
        <img
          src="/images/apple-icon.png"
          className="crayons-logo__image"
          alt="Acme Inc."
        />
      </span>
      <span className="crayons-logo crayons-logo--xl">
        <img
          src="/images/apple-icon.png"
          className="crayons-logo__image"
          alt="Acme Inc."
        />
      </span>
      <span className="crayons-logo crayons-logo--2xl">
        <img
          src="/images/apple-icon.png"
          className="crayons-logo__image"
          alt="Acme Inc."
        />
      </span>
      <span className="crayons-logo crayons-logo--3xl">
        <img
          src="/images/apple-icon.png"
          className="crayons-logo__image"
          alt="Acme Inc."
        />
      </span>
    </div>
  </div>
));
