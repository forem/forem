import { h } from 'preact';
import { useState } from 'preact/hooks';
import { Modal } from '@crayons/Modal/Modal';

export const AdminUserActionsModal = ({
  title,
  size,
  children,
  open = true,
}) => {
  const [isOpen, setIsOpen] = useState(open);

  return isOpen ? (
    <Modal
      title={title}
      size={size}
      onClose={() => {
        setIsOpen(false);
      }}
    >
      {children}
    </Modal>
  ) : null;
};

// TODO: proptypes and docs
