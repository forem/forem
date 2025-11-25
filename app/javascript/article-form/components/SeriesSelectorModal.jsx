import { h, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { Modal, ButtonNew as Button } from '@crayons';
import PlusIcon from '@images/plus.svg';

/**
 * SeriesSelectorModal - An interactive modal for selecting or creating series
 *
 * @param {Object} props
 * @param {boolean} props.isOpen Whether the modal is currently open
 * @param {Function} props.onClose Callback when modal should close
 * @param {Array} props.allSeries Available series to choose from
 * @param {string} props.currentSeries Currently selected series slug
 * @param {string|number|null} props.organizationId Current organization ID
 * @param {Function} props.onSelectSeries Callback when a series is selected
 * @param {Function} props.onCreateSeries Callback when a new series is created
 */
export const SeriesSelectorModal = ({
  isOpen,
  onClose,
  allSeries = [],
  currentSeries = '',
  organizationId = null,
  onSelectSeries,
  onCreateSeries,
}) => {
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newSeriesName, setNewSeriesName] = useState('');

  // Reset form when modal opens/closes
  useEffect(() => {
    if (!isOpen) {
      setShowCreateForm(false);
      setNewSeriesName('');
    }
  }, [isOpen]);

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
    onClose();
  };

  const handleCreateSeries = (e) => {
    e.preventDefault();
    if (!newSeriesName.trim()) return;

    if (onCreateSeries) {
      const seriesEvent = {
        target: {
          name: 'series',
          value: newSeriesName.trim(),
        },
        preventDefault: () => {},
      };
      onCreateSeries(seriesEvent);
    }
    onClose();
  };

  if (!isOpen) return null;

  return (
    <Modal
      title="Manage Series"
      onClose={onClose}
      size="medium"
      backdropDismissible
      className="series-selector-modal"
    >
      <div className="series-selector-modal__content">
        {!showCreateForm ? (
          <Fragment>
            {filteredSeries.length > 0 && (
              <div className="series-selector-modal__existing">
                <h3 className="crayons-subtitle-3 mb-4">Select an existing series</h3>
                <div className="series-selector-modal__series-grid">
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
                        className={`series-selector-modal__series-card ${
                          isSelected ? 'series-selector-modal__series-card--selected' : ''
                        }`}
                        onClick={() => handleSelectSeries(series)}
                        aria-pressed={isSelected}
                      >
                        <div className="series-selector-modal__series-card-content">
                          <span className="series-selector-modal__series-name">
                            {displayLabel}
                          </span>
                          {series.is_personal && (
                            <span className="series-selector-modal__series-badge series-selector-modal__series-badge--personal">
                              Personal
                            </span>
                          )}
                          {!series.is_personal && series.organization_name && (
                            <span className="series-selector-modal__series-badge">
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

            <div className="series-selector-modal__create-section">
              <Button
                variant="primary"
                icon={PlusIcon}
                onClick={() => setShowCreateForm(true)}
                className="series-selector-modal__create-btn"
              >
                Create new series
              </Button>
              <p className="crayons-field__description mt-2">
                Give your series a unique name. The series will be visible once it has multiple posts.
              </p>
            </div>

            {currentSeries && (
              <div className="series-selector-modal__current mt-4 pt-4 border-t border-base-10">
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
                    onClose();
                  }}
                >
                  Remove series
                </Button>
              </div>
            )}
          </Fragment>
        ) : (
          <div className="series-selector-modal__create-form">
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
                <Button variant="primary" type="submit" disabled={!newSeriesName.trim()}>
                  Create series
                </Button>
                <Button
                  variant="secondary"
                  type="button"
                  onClick={() => {
                    setShowCreateForm(false);
                    setNewSeriesName('');
                  }}
                >
                  Cancel
                </Button>
              </div>
            </form>
          </div>
        )}
      </div>
    </Modal>
  );
};

SeriesSelectorModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
  allSeries: PropTypes.array.isRequired,
  currentSeries: PropTypes.string,
  organizationId: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number,
  ]),
  onSelectSeries: PropTypes.func.isRequired,
  onCreateSeries: PropTypes.func.isRequired,
};

SeriesSelectorModal.displayName = 'SeriesSelectorModal';

