import { h } from 'preact';
import { useState } from 'preact/hooks';
import notes from './modals.mdx';
import { Modal, ButtonNew as Button } from '@crayons';

export default {
  title: 'Components/Modals',
  parameters: {
    docs: {
      page: notes,
    },
  },
  argTypes: {
    size: {
      control: {
        type: 'select',
        options: {
          default: 'default',
          small: 's',
          medium: 'm',
        },
      },
      table: {
        defaultValue: { summary: 'default' },
      },
    },
    overlay: {
      table: {
        defaultValue: { summary: true },
      },
    },
    title: {
      control: {
        type: 'text',
      },
      table: {
        defaultValue: { summary: 'Modal title' },
      },
    },
  },
};

export const Default = (args) => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <div>
      <Button onClick={() => setIsModalOpen(true)}>Open modal</Button>
      {isModalOpen && (
        <Modal onClose={() => setIsModalOpen(false)} {...args}>
          <p>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse
            odio est, ultricies vel euismod ut, fringilla quis tellus. Sed at
            dui mi. Fusce cursus nibh lectus, vitae lobortis orci volutpat quis.{' '}
          </p>
        </Modal>
      )}
    </div>
  );
};

Default.args = {
  size: 'default',
  title: 'My modal',
  overlay: true,
};
