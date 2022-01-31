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
          Small: 'small',
          'Medium (default)': undefined,
          Large: 'large',
        },
      },
      description:
        'There are several sizes available - use appropriate size depending on how much content you need to display inside modal.',
      table: {
        defaultValue: { summary: 'default' },
      },
    },
    noBackdrop: {
      description: 'Removes the default backdrop overlay.',
      table: {
        defaultValue: { summary: true },
      },
    },
    backdropDismissible: {
      description:
        'If `backdrop` is visible you can also make it clickable so clicking it would dismiss the Modal',
      table: {
        defaultValue: { summary: false },
      },
    },
    prompt: {
      description:
        'Special style for Modals that should be used for short prompts (short messages or confirmations). Prompts can only be used with size `small` (`s`).',
      table: {
        defaultValue: { summary: false },
      },
    },
    centered: {
      description:
        'In some cases it might be "nicer" to center Modals content. This will only work with `prompt` though.',
      table: {
        defaultValue: { summary: false },
      },
    },
    title: {
      control: {
        type: 'text',
      },
      description: '🤷‍♂️',
      table: {
        defaultValue: { summary: 'Modal title' },
      },
    },
  },
};

const Template = (args) => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <div>
      <Button onClick={() => setIsModalOpen(true)}>Open modal</Button>
      {isModalOpen && (
        <Modal onClose={() => setIsModalOpen(false)} {...args}>
          <div class="flex flex-col gap-4">
            <p>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit.
              Suspendisse odio est, ultricies vel euismod ut, fringilla quis
              tellus. Sed at dui mi. Fusce cursus nibh lectus, vitae lobortis
              orci volutpat quis.
            </p>
            {!args.prompt && (
              <p>
                Sed at dui mi. Fusce cursus nibh lectus, vitae lobortis orci
                volutpat quis. Lorem ipsum dolor sit amet, consectetur
                adipiscing elit. Suspendisse odio est, ultricies vel euismod ut,
                fringilla quis tellus. Sed at dui mi. Fusce cursus nibh lectus,
                vitae lobortis orci volutpat quis.
              </p>
            )}
          </div>
        </Modal>
      )}
    </div>
  );
};

export const Default = Template.bind({});
Default.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: false,
  backdropDismissible: false,
  prompt: false,
  centered: false,
};

export const Prompt = Template.bind({});
Prompt.args = {
  size: undefined,
  title:
    'Are you sure you want to remove Paweł Ludwiczak from Design Department?',
  noBackdrop: false,
  backdropDismissible: false,
  prompt: true,
  centered: false,
};

export const PromptCentered = Template.bind({});
PromptCentered.args = {
  size: undefined,
  title:
    'Are you sure you want to remove Paweł Ludwiczak from Design Department?',
  noBackdrop: false,
  backdropDismissible: false,
  prompt: true,
  centered: true,
};

export const BackdropDismissible = Template.bind({});
BackdropDismissible.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: false,
  backdropDismissible: true,
  prompt: false,
  centered: false,
};

export const NoBackdrop = Template.bind({});
NoBackdrop.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: true,
  backdropDismissible: false,
  prompt: false,
  centered: false,
};
