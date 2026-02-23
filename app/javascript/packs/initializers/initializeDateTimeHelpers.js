import { localizeTimeElements, timestampToLocalDateTimeShort } from '../../utilities/localDateTime';

export function initializeDateHelpers() {
  // Date without year: Jul 12
  localizeTimeElements(document.querySelectorAll('time.date-no-year'), {
    month: 'short',
    day: 'numeric',
  });

  // Full date: Jul 12, 2020
  localizeTimeElements(document.querySelectorAll('time.date'), {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  // Date with short year: Jul 12 '20
  localizeTimeElements(document.querySelectorAll('time.date-short-year'), {
    year: '2-digit',
    month: 'short',
    day: 'numeric',
  });

  // Format all time elements with datetime attributes that don't have specific classes
  // This ensures dates are displayed in user's local timezone
  formatAllTimeElements();
}

/**
 * Formats all time elements with datetime attributes to use user's local timezone.
 * Can be called after dynamically inserting content.
 */
export function formatAllTimeElements(container = document) {
  const timeElements = container.querySelectorAll('time[datetime]:not(.date):not(.date-no-year):not(.date-short-year)');
  for (let i = 0; i < timeElements.length; i += 1) {
    const element = timeElements[i];
    const timestamp = element.getAttribute('datetime');
    
    if (timestamp) {
      // Use the same format as timestampToLocalDateTimeShort (handles year automatically)
      const formattedDate = timestampToLocalDateTimeShort(timestamp);
      if (formattedDate) {
        // Check if element has child nodes (like spans for time-ago indicators)
        const hasChildren = element.children.length > 0;
        const currentText = element.textContent.trim();
        
        if (!hasChildren) {
          // Simple case: element only contains text, replace it
          element.textContent = formattedDate;
        } else {
          // Complex case: element has children (like time-ago spans)
          // Try to replace just the date text while preserving children
          // Find the text node and replace it
          const textNodes = Array.from(element.childNodes).filter(node => node.nodeType === Node.TEXT_NODE);
          if (textNodes.length > 0) {
            // Replace the first text node (which should be the date)
            textNodes[0].textContent = formattedDate + ' ';
          }
        }
      }
    }
  }
}

// Make it available globally for legacy code
if (typeof globalThis !== 'undefined') {
  globalThis.formatAllTimeElements = formatAllTimeElements; // eslint-disable-line no-undef
}
