import { h } from 'preact';

export const HeaderSection = ({}) => (
  <div className="request_manager_header crayons-card mb-6 grid grid-flow-row gap-6 p-6">
    <h1>
      Request Center{' '}
      <span role="img" aria-label="handshake">
        🤝
      </span>
    </h1>
  </div>
);
