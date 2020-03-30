import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Form Components',
};

export const Description = () => (
  <div className="container">
    <h2>Form elements</h2>
    <p>
      Because of accessibility most (ideally all) fields should have label
      above.
    </p>
    <p>
      Fields can also have optional description - between Label and Field
      itself.
    </p>
    <p>
      Fields can also have additional optional description, for example
      characters count.
    </p>
    <h3>Fields with Checkboxes & Radios</h3>
    <p>
      Labels for checkboxes and radios should be placed next to the form
      element.
    </p>
    <p>Using additional description is optional.</p>
    <p>
      It is possible to group checkboxes or radios into logical sections.
      Section may require having it’s own label (title).
    </p>
  </div>
);

Description.story = { name: 'description' };
