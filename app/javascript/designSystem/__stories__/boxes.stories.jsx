import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

const Grid = ({ children }) => (
  <div
    style={{
      display: 'grid',
      'grid-template-columns': '1fr',
      'grid-gap': '16px',
    }}
  >
    {children}
  </div>
);

Grid.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};

storiesOf('Base/Components/Boxes', module)
  .add('Description', () => (
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
        Use style that makes the most sense for you current use case. It’s
        pretty obvious when to use Danger, Warning and Success. But for Default
        and Info - it’s more up to designer to make a good call :).
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
  ))
  .add('Level 0', () => (
    <Grid>
      <div className="crayons-box">box, level 0</div>
      <div className="crayons-box crayons-box--filled ">
        filled box, level 0
      </div>
      <div className="crayons-box crayons-box--danger">box, level 0</div>
      <div className="crayons-box crayons-box--danger crayons-box--filled ">
        filled box, level 0
      </div>
      <div className="crayons-box crayons-box--warning">box, level 0</div>
      <div className="crayons-box crayons-box--warning crayons-box--filled ">
        filled box, level 0
      </div>
      <div className="crayons-box crayons-box--success">box, level 0</div>
      <div className="crayons-box crayons-box--success crayons-box--filled ">
        filled box, level 0
      </div>
      <div className="crayons-box crayons-box--info">box, level 0</div>
      <div className="crayons-box crayons-box--info crayons-box--filled ">
        filled box, level 0
      </div>
    </Grid>
  ))
  .add('Level 1', () => (
    <Grid>
      <div className="crayons-box crayons-box--level-1">box, level 1</div>
      <div className="crayons-box crayons-box--filled">filled box, level 1</div>
      <div className="crayons-box crayons-box--danger">box, level 1</div>
      <div className="crayons-box crayons-box--danger crayons-box--filled crayons-box--level-1">
        filled box, level 1
      </div>
      <div className="crayons-box crayons-box--warning">box, level 1</div>
      <div className="crayons-box crayons-box--warning crayons-box--filled crayons-box--level-1">
        filled box, level 1
      </div>
      <div className="crayons-box crayons-box--success">box, level 1</div>
      <div className="crayons-box crayons-box--success crayons-box--filled crayons-box--level-1">
        filled box, level 1
      </div>
      <div className="crayons-box crayons-box--info">box, level 1</div>
      <div className="crayons-box crayons-box--info crayons-box--filled crayons-box--level-1">
        filled box, level 1
      </div>
    </Grid>
  ))
  .add('Level 2', () => (
    <Grid>
      <div className="crayons-box crayons-box--level-2">box, level 2</div>
      <div className="crayons-box crayons-box--filled">filled box, level 2</div>
      <div className="crayons-box crayons-box--danger">box, level 2</div>
      <div className="crayons-box crayons-box--danger crayons-box--filled crayons-box--level-2">
        filled box, level 2
      </div>
      <div className="crayons-box crayons-box--warning">box, level 2</div>
      <div className="crayons-box crayons-box--warning crayons-box--filled crayons-box--level-2">
        filled box, level 2
      </div>
      <div className="crayons-box crayons-box--success">box, level 2</div>
      <div className="crayons-box crayons-box--success crayons-box--filled crayons-box--level-2">
        filled box, level 2
      </div>
      <div className="crayons-box crayons-box--info">box, level 2</div>
      <div className="crayons-box crayons-box--info crayons-box--filled crayons-box--level-2">
        filled box, level 2
      </div>
    </Grid>
  ))
  .add('Level 3', () => (
    <Grid>
      <div className="crayons-box crayons-box--level-3">box, level 3</div>
      <div className="crayons-box crayons-box--filled">filled box, level 3</div>
      <div className="crayons-box crayons-box--danger">box, level 3</div>
      <div className="crayons-box crayons-box--danger crayons-box--filled crayons-box--level-3">
        filled box, level 3
      </div>
      <div className="crayons-box crayons-box--warning">box, level 3</div>
      <div className="crayons-box crayons-box--warning crayons-box--filled crayons-box--level-3">
        filled box, level 3
      </div>
      <div className="crayons-box crayons-box--success">box, level 3</div>
      <div className="crayons-box crayons-box--success crayons-box--filled crayons-box--level-3">
        filled box, level 3
      </div>
      <div className="crayons-box crayons-box--info">box, level 3</div>
      <div className="crayons-box crayons-box--info crayons-box--filled crayons-box--level-3">
        filled box, level 3
      </div>
    </Grid>
  ));
