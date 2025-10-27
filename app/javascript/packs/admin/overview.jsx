import { initializeDropdown } from '@utilities/dropdownUtils';

initializeDropdown({
  triggerElementId: 'timeperiods-trigger',
  dropdownContentId: 'timeperiods-dropdown',
});

// Fetch and display stats
async function fetchStats(period = 7) {
  try {
    const response = await fetch(`/admin/stats?period=${period}`);
    const data = await response.json();
    updateStatsDisplay(data);
  } catch (error) {
    console.error('Error fetching stats:', error);
    showError();
  }
}

function updateStatsDisplay(data) {
  const statElements = {
    published_posts: document.querySelector('[data-stat="published_posts"]'),
    comments: document.querySelector('[data-stat="comments"]'),
    public_reactions: document.querySelector('[data-stat="public_reactions"]'),
    new_users: document.querySelector('[data-stat="new_users"]'),
  };

  Object.keys(statElements).forEach((key) => {
    if (statElements[key]) {
      statElements[key].textContent = data[key].toLocaleString();
    }
  });
}

function showError() {
  const container = document.getElementById('admin-stats-container');
  if (container) {
    container.innerHTML = '<div class="color-accent-danger">Error loading statistics. Please try again.</div>';
  }
}

// Handle period selector changes
document.addEventListener('DOMContentLoaded', () => {
  // Load initial stats
  fetchStats(7);

  // Add event listeners to period selectors
  const periodSelectors = document.querySelectorAll('.js-period-selector');
  periodSelectors.forEach((selector) => {
    selector.addEventListener('change', (e) => {
      const period = e.target.dataset.period;
      fetchStats(period);
    });
  });
});
