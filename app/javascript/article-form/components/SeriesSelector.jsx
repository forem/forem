import { h, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { ButtonNew as Button } from '@crayons';
import PlusIcon from '@images/plus.svg';

/**
 * SeriesSelector - An interactive component for selecting or creating series
 * Can be embedded in modals or other containers
 *
 * @param {Object} props
 * @param {Array} props.allSeries Available series to choose from
 * @param {string} props.currentSeries Currently selected series slug
 * @param {string|number|null} props.organizationId Current organization ID
 * @param {Function} props.onSelectSeries Callback when a series is selected
 * @param {Function} props.onCreateSeries Callback when a new series is created
 * @param {boolean} props.showCreateForm Whether to show the create form (controlled from parent)
 * @param {Function} props.onShowCreateFormChange Callback when showCreateForm should change
 */
export const SeriesSelector = ({
  allSeries = [],
  currentSeries = '',
  organizationId = null,
  onSelectSeries,
  onCreateSeries,
  showCreateForm: controlledShowCreateForm,
  onShowCreateFormChange,
}) => {
  // Use controlled state if provided, otherwise use internal state
  const isControlled = controlledShowCreateForm !== undefined && onShowCreateFormChange !== undefined;
  const [internalShowCreateForm, setInternalShowCreateForm] = useState(false);
  const showCreateForm = isControlled ? controlledShowCreateForm : internalShowCreateForm;
  const setShowCreateForm = isControlled ? onShowCreateFormChange : setInternalShowCreateForm;
  
  const [newSeriesName, setNewSeriesName] = useState('');
  const [isCreating, setIsCreating] = useState(false);
  const [pendingSeriesName, setPendingSeriesName] = useState(null);

  // Close the create form when the series we created appears in currentSeries or allSeries
  useEffect(() => {
    if (pendingSeriesName && showCreateForm) {
      const wasCreated = 
        currentSeries === pendingSeriesName || 
        allSeries.some(s => {
          const slug = typeof s === 'string' ? s : s.slug;
          return slug === pendingSeriesName;
        });
      
      if (wasCreated) {
        setShowCreateForm(false);
        setNewSeriesName('');
        setPendingSeriesName(null);
        setIsCreating(false);
      }
    }
  }, [currentSeries, allSeries, pendingSeriesName, showCreateForm]);

  // Normalize series data for backward compatibility
  const normalizedSeries = allSeries.map((item) => {
    if (typeof item === 'string') {
      return {
        slug: item,
        organization_id: null,
        organization_name: null,
        is_personal: true,
      };
    }
    return item;
  });

  // Filter series based on selected organization
  const filteredSeries = normalizedSeries.filter((item) => {
    if (!organizationId || organizationId === '') {
      return item.is_personal;
    }
    return (
      item.is_personal ||
      item.organization_id === parseInt(organizationId, 10)
    );
  });

  // Check if current series is in the existing filtered series
  const isCurrentSeriesInExisting = currentSeries && filteredSeries.some((s) => s.slug === currentSeries);

  const handleSelectSeries = (series) => {
    if (onSelectSeries) {
      // Parse slug and organization_id from the series object
      const seriesEvent = {
        target: {
          name: 'series',
          value: series.slug,
        },
        preventDefault: () => {},
      };
      onSelectSeries(seriesEvent);

      // Update organizationId if needed
      const currentOrgId = String(organizationId || '');
      const newOrgId = series.organization_id
        ? String(series.organization_id)
        : '';

      if (newOrgId !== currentOrgId) {
        const orgEvent = {
          target: {
            name: 'organizationId',
            value: newOrgId,
          },
          preventDefault: () => {},
        };
        onSelectSeries(orgEvent);
      }
    }
  };

  const handleCreateSeries = (e) => {
    e.preventDefault();
    if (!newSeriesName.trim() || isCreating) return;

    if (onCreateSeries) {
      const seriesNameToCreate = newSeriesName.trim();
      setIsCreating(true);
      setPendingSeriesName(seriesNameToCreate);
      
      const seriesEvent = {
        target: {
          name: 'series',
          value: seriesNameToCreate,
        },
        preventDefault: () => {},
      };
      onCreateSeries(seriesEvent);
    }
  };

  return (
    <div className="series-selector">
      {!showCreateForm ? (
        <Fragment>
          {/* Show existing series list only if:
              1. No current series selected (so user can pick one), OR
              2. Current series is in the existing list (show list with highlighted selection)
          */}
          {filteredSeries.length > 0 && (!currentSeries || isCurrentSeriesInExisting) && (
            <div className="series-selector__existing mb-6">
              <h3 className="crayons-subtitle-3 mb-4">Select an existing series</h3>
              <div className="series-selector__series-grid">
                {filteredSeries.map((series, index) => {
                  const isSelected = series.slug === currentSeries;
                  let displayLabel = series.slug;
                  if (!series.is_personal && series.organization_name) {
                    displayLabel = `${series.slug} (${series.organization_name})`;
                  }

                  return (
                    <button
                      key={`series-${index}`}
                      type="button"
                      className={`series-selector__series-card ${
                        isSelected ? 'series-selector__series-card--selected' : ''
                      }`}
                      onClick={() => handleSelectSeries(series)}
                      aria-pressed={isSelected}
                    >
                      <div className="series-selector__series-card-content">
                        <span className="series-selector__series-name">
                          {displayLabel}
                        </span>
                        {!series.is_personal && series.organization_name && (
                          <span className="series-selector__series-badge">
                            {series.organization_name}
                          </span>
                        )}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {!currentSeries && (
            <div 
              className="series-selector__create-section"
              onMouseDown={(e) => e.stopPropagation()}
              onClick={(e) => e.stopPropagation()}
            >
              <Button
                variant="primary"
                icon={PlusIcon}
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  setShowCreateForm(true);
                }}
                onMouseDown={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                }}
                className="series-selector__create-btn"
                type="button"
              >
                Create new series
              </Button>
              <p className="crayons-field__description mt-2">
                Give your series a unique name. The series will be visible once it has multiple posts.
              </p>
            </div>
          )}

          {currentSeries && (
            <div className={`series-selector__current ${isCurrentSeriesInExisting ? 'mt-4 pt-4 border-t border-base-10' : ''}`}>
              <p className="crayons-field__description mb-2">
                <strong>Currently selected:</strong> {currentSeries}
              </p>
              <Button
                variant="secondary"
                onClick={() => {
                  const clearEvent = {
                    target: {
                      name: 'series',
                      value: '',
                    },
                    preventDefault: () => {},
                  };
                  onSelectSeries(clearEvent);
                }}
              >
                Remove series
              </Button>
            </div>
          )}
        </Fragment>
      ) : (
        <div className="series-selector__create-form">
          <h3 className="crayons-subtitle-3 mb-4">Create a new series</h3>
          <form onSubmit={handleCreateSeries}>
            <div className="crayons-field mb-4">
              <label htmlFor="new-series-name" className="crayons-field__label">
                Series name
              </label>
              <input
                type="text"
                id="new-series-name"
                className="crayons-textfield"
                value={newSeriesName}
                onChange={(e) => setNewSeriesName(e.target.value)}
                placeholder="Enter series name..."
                required
              />
            </div>
            <div className="flex gap-2">
              <Button variant="primary" type="submit" disabled={!newSeriesName.trim() || isCreating}>
                {isCreating ? 'Creating...' : 'Create series'}
              </Button>
              <Button
                variant="secondary"
                type="button"
                onClick={() => {
                  setShowCreateForm(false);
                  setNewSeriesName('');
                  setIsCreating(false);
                }}
                disabled={isCreating}
              >
                Cancel
              </Button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};

SeriesSelector.propTypes = {
  allSeries: PropTypes.array.isRequired,
  currentSeries: PropTypes.string,
  organizationId: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number,
  ]),
  onSelectSeries: PropTypes.func.isRequired,
  onCreateSeries: PropTypes.func.isRequired,
  showCreateForm: PropTypes.bool,
  onShowCreateFormChange: PropTypes.func,
};

SeriesSelector.displayName = 'SeriesSelector';

