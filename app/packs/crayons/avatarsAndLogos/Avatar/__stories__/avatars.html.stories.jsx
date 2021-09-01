import { h } from 'preact';
import '../../../storybook-utilities/designSystem.scss';
import notes from '../../avatars-and-logos.md';

export default {
  title: 'Components/Avatars & Logos/Avatars/HTML',
  parameters: {
    notes,
  },
};

export const Default = () => (
  <span className="crayons-avatar">
    <img
      src="/images/apple-icon.png"
      className="crayons-avatar__image"
      alt="Ben"
    />
  </span>
);

Default.story = { name: 'default (small)' };

export const Large = () => (
  <span className="crayons-avatar crayons-avatar--l">
    <img
      src="/images/apple-icon.png"
      className="crayons-avatar__image"
      alt="Ben"
    />
  </span>
);

Large.story = { name: 'large' };

export const ExtraLarge = () => (
  <span className="crayons-avatar crayons-avatar--xl">
    <img
      src="/images/apple-icon.png"
      className="crayons-avatar__image"
      alt="Ben"
    />
  </span>
);

ExtraLarge.story = { title: 'extra large' };

export const DoubleXL = () => (
  <span className="crayons-avatar crayons-avatar--2xl">
    <img
      src="/images/apple-icon.png"
      className="crayons-avatar__image"
      alt="Ben"
    />
  </span>
);

DoubleXL.story = { name: '2XL' };

export const TripleXL = () => (
  <span className="crayons-avatar crayons-avatar--3xl">
    <img
      src="/images/apple-icon.png"
      className="crayons-avatar__image"
      alt="Ben"
    />
  </span>
);

TripleXL.story = { name: '3XL' };
