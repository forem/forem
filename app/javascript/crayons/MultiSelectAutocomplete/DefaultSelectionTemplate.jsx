import { h } from 'preact';
import { Icon, ButtonNew as Button } from '@crayons';
import { Close } from '@images/x.svg';

export const DefaultSelectionTemplate = ({ name, onEdit, onDeselect }) => (
  <div role="group" aria-label={name} className="flex mr-1 mb-1 w-max">
    <Button
      variant="secondary"
      className="c-autocomplete--multi__selected p-1 cursor-text"
      aria-label={`Edit ${name}`}
      onClick={onEdit}
    >
      {name}
    </Button>
    <Button
      variant="secondary"
      className="c-autocomplete--multi__selected p-1"
      aria-label={`Remove ${name}`}
      onClick={onDeselect}
    >
      <Icon src={Close} />
    </Button>
  </div>
);
