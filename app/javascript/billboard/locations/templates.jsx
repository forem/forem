import { h } from 'preact';
import { useCallback } from 'preact/hooks';
import { ButtonNew as Button, Icon } from '@crayons';
import Close from '@images/x.svg';

/**
 * Higher-order component that returns a template responsible for the layout of
 * a selected location
 *
 * @returns {h.JSX.ElementType}
 */
export const SelectedLocation = ({
  displayName,
  onNameClick,
  label,
  ExtraInfo,
}) => {
  const Template = ({ onEdit: _, onDeselect, ...location }) => {
    const onClick = useCallback(() => onNameClick(location), [location]);

    return (
      <div
        role="group"
        aria-label={location.name}
        className="c-autocomplete--multi__tag-selection flex mr-2 mb-2 w-max"
      >
        <Button
          aria-label={label}
          onClick={onClick}
          className="c-autocomplete--multi__selected p-1 flex flex-col"
        >
          {location.name}
          {ExtraInfo && <ExtraInfo {...location} />}
        </Button>
        <Button
          aria-label={`Remove ${location.name}`}
          onClick={onDeselect}
          className="c-autocomplete--multi__selected p-1"
        >
          <Icon src={Close} />
        </Button>
      </div>
    );
  };

  Template.displayName = displayName;
  return Template;
};
