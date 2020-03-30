import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';
import { defaultChildrenPropTypes } from '../../../src/components/common-prop-types';

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

export default {
  title: 'Components/Boxes/HTML',
};

export const Level0 = () => (
  <Grid>
    <div className="crayons-box">box, level 0</div>
    <div className="crayons-box crayons-box--filled ">filled box, level 0</div>
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
);

Level0.story = {
  name: 'level 0',
};

export const Level1 = () => (
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
);

Level1.story = {
  name: 'level 1',
};

export const Level2 = () => (
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
);

Level2.story = {
  name: 'level 2',
};

export const Level3 = () => (
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
);

Level3.story = {
  name: 'level 3',
};
