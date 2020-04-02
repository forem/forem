import { h } from 'preact';

export default {
  title: 'Components/Buttons',
};

export const Description = () => (
  <div className="container">
    <h2>Buttons</h2>
    <p>
      Use Danger style only for destructive actions like removing something. Do
      not use it for, for example “unfollow” action.
    </p>
    <p>
      If you have to use several buttons together, keep in mind you should
      always have ONE Primary button. Rest of them should be Secondary and/or
      Outlined and/or Text buttons.
    </p>
    <p>
      It is ok to use ONLY Secondary or outlined button without being
      accompanied by Primary one.
    </p>
    <p>
      For Stacking buttons (vertically or horizontally) please use 8px spacing
      unit for default size buttons (no matter if stacking horizontally or
      vertically).
    </p>
  </div>
);

Description.story = {
  name: 'description',
};
