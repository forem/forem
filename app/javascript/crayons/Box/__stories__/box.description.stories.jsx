import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Boxes',
};

export const Description = () => (
  <div className="container">
    <h2>Boxes</h2>
    <p>
      “Box” will be a background element used for many other components, for
      example banners, dropdowns, modals. This component does not have any
      guidelines in terms of placement or spacing, since it’s supposed to be
      used to build other components.
    </p>
    <p>There are:</p>
    <ul>
      <li>2 types: outlined & filled,</li>
      <li>5 styles: default, danger, warning, info, success,</li>
      <li>4 eleveations: 0, 1, 2, 3.</li>
    </ul>
    <p>
      By default use “outlined” type unless you really have to make something
      stand out - then use “filled”. But double check if it makes sense since
      “filled” style really steals attention.
    </p>
    <p>
      Use style that makes the most sense for you current use case. It’s pretty
      obvious when to use Danger, Warning and Success. But for Default and Info
      - it’s more up to designer to make a good call :).
    </p>
    <p>Elevations should define what kind of element it is:</p>
    <ul>
      <li>0: something inside content.</li>
      <li>
        1: that can also be used in content but for elements that need more
        attention, like notices...
      </li>
      <li>2: dropdowns</li>
      <li>3: modals</li>
    </ul>
  </div>
);

Description.story = {
  name: 'description',
};
