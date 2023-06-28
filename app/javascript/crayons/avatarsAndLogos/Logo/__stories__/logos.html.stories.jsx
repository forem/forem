import { h } from 'preact';
import notes from '../../avatars-and-logos.mdx';

export default {
  title: 'Components/Avatars & Logos/Logos',
  parameters: {
    docs: {
      page: notes,
    },
  },
};

export const Default = () => (
  <span className="crayons-logo">
    <img
      src="/images/apple-icon.png"
      className="crayons-logo__image"
      alt="Acme Inc."
    />
  </span>
);

Default.storyName = 'default (small)';

export const Large = () => (
  <span className="crayons-logo crayons-logo--l">
    <img
      src="/images/apple-icon.png"
      className="crayons-logo__image"
      alt="Acme Inc."
    />
  </span>
);

Large.storyName = 'large';

export const ExtraLarge = () => (
  <span className="crayons-logo crayons-logo--xl">
    <img
      src="/images/apple-icon.png"
      className="crayons-logo__image"
      alt="Acme Inc."
    />
  </span>
);

ExtraLarge.storyName = 'extra large';

export const DoubleXL = () => (
  <span className="crayons-logo crayons-logo--2xl">
    <img
      src="/images/apple-icon.png"
      className="crayons-logo__image"
      alt="Acme Inc."
    />
  </span>
);

DoubleXL.storyName = '2XL';

export const TripleXL = () => (
  <span className="crayons-logo crayons-logo--3xl">
    <img
      src="/images/apple-icon.png"
      className="crayons-logo__image"
      alt="Acme Inc."
    />
  </span>
);

TripleXL.storyName = '3XL';
