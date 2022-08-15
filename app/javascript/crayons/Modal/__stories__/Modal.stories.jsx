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
    sheetAlign: {
      type: 'select',
      options: {
        'Center (default)': 'center',
        Left: 'left',
        Right: 'right',
      },
      description:
        'Modals will default to showing in the center of the screen. When using the `sheet` variant, it is possible to position to left or right of screen',
      table: {
        defaultValue: { summary: 'center' },
      },
    },
    noBackdrop: {
      description: 'Removes the default backdrop overlay.',
      table: {
        defaultValue: { summary: true },
      },
    },
    showHeader: {
      description:
        'Whether or not to display the standard header (with title and close button). If `false`, make sure to provide an alternative close button.',
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
    sheet: {
      description:
        'Special style to display the modal as full view height. Useful for larger chunks of content, and may be anchored to left or right of screen using the `align` prop',
      table: {
        defaultValue: { summary: false },
      },
    },
    centered: {
      description:
        'In some cases it might be "nicer" to center modal content. This will only work with `prompt` though.',
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
          {!args.showHeader && (
            <Button variant="primary" onClick={() => setIsModalOpen(false)}>
              OK
            </Button>
          )}
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
  sheet: false,
  showHeader: true,
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
  sheet: false,
  showHeader: true,
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
  sheet: false,
  showHeader: true,
};

export const Sheet = Template.bind({});
Sheet.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: false,
  backdropDismissible: false,
  prompt: false,
  centered: false,
  sheet: true,
  showHeader: true,
};

export const SheetLeftAligned = Template.bind({});
SheetLeftAligned.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: false,
  backdropDismissible: false,
  prompt: false,
  centered: false,
  sheet: true,
  sheetAlign: 'left',
  showHeader: true,
};

export const SheetRightAligned = Template.bind({});
SheetRightAligned.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: false,
  backdropDismissible: false,
  prompt: false,
  centered: false,
  sheet: true,
  sheetAlign: 'right',
  showHeader: true,
};

export const BackdropDismissible = Template.bind({});
BackdropDismissible.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: false,
  backdropDismissible: true,
  prompt: false,
  centered: false,
  sheet: false,
  showHeader: true,
};

export const NoBackdrop = Template.bind({});
NoBackdrop.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: true,
  backdropDismissible: false,
  prompt: false,
  centered: false,
  sheet: false,
  showHeader: true,
};

export const NoHeader = Template.bind({});
NoHeader.args = {
  size: undefined,
  title: 'Modal title',
  noBackdrop: false,
  backdropDismissible: false,
  prompt: false,
  centered: false,
  sheet: false,
  showHeader: false,
};
