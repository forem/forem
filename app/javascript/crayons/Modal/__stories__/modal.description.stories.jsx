import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Modals',
};

export const Description = () => (
  <div className="container">
    <h2>Modals</h2>
    <p>
      Modals should be positioned centered in relation to entire viewport. So
      relation to its tirgger doesn’t really matter.
    </p>
    <p>There are 3 sizes of modals:</p>
    <ul>
      <li>S(mall): 480px width with 24px padding</li>
      <li>Default: 640px width with 32px padding</li>
      <li>L(arge): 800px width with 48px padding</li>
    </ul>
    <p>Use your best judgements when choosing the right size.</p>
    <p>
      If you need to utilize entire modal area and you have to get rid of
      default padding, please use modifier class
      <code>crayons-modal--padding-0</code>
      .
    </p>
    <p>
      FYI: Modals use “Box” component as background, with Level 3 elevation.
    </p>
  </div>
);

Description.story = {
  name: 'description',
};
