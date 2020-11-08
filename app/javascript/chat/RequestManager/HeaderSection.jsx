import { h } from 'preact';

/**
 * This component render the Header for request section
 *
 * @component
 *
 * @example
 *
 * <HeaderSection />
 *
 */

export default function HeaderSection() {
  return (
    <div className="request_manager_header crayons-card mb-6 grid grid-flow-row gap-6 p-6">
      <h1>
        Request Center{' '}
        <span role="img" aria-label="handshake">
          🤝
        </span>
      </h1>
    </div>
  );
}
