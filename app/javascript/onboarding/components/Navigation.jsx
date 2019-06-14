import { h, Component } from 'preact';

export default ({ next, prev }) => (
  <div className="navigation">
    <button onClick={prev} className="back-button">
      BACK
    </button>
    <button onClick={next} className="next-button pill green">
      Continue
    </button>
  </div>
);
