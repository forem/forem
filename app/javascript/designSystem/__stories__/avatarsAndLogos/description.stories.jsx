import { h } from 'preact';

import '../designSystem.scss';

export default { title: 'Components/HTML/Avatars & Logos' };

export const Description = () => (
  <div className="container">
    <h2>Avatars &amp; Logos</h2>
    <p>An image representing a user is called an avatar.</p>
    <p>An image representing a company or organization is called a logo.</p>
    <p>
      To make a distinction between these two different entities we should keep
      them visually different. For Avatars, we gonna use circle shape. And for
      Logos we gonna use square shape. This will help recognize what is what in
      a heartbeat.
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
    <p>Remember to use descriptive alt=&quot;&quot; values!</p>
  </div>
);

Description.story = { name: 'description' };
