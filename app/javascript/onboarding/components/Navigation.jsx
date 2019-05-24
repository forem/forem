import { h, Component } from 'preact';

export default ({ next, prev }) => (
  <div>
    <button onClick={prev} className="back-button">
      BACK
    </button>
    <button onClick={next} className="next-button">
      NEXT
    </button>
  </div>
);
