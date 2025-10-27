// Sticky sidebar billboard implementation
function initializeStickyBillboard() {
  const stickyElement = document.getElementById('sticky-billboard');
  
  if (!stickyElement) {
    return;
  }
  
  // Cache DOM queries and measurements
  const sidebar = document.querySelector('.sidebar-additional');
  if (!sidebar) return;
  
  // Pre-calculate values that don't change
  const sidebarWidth = sidebar.offsetWidth;
  const sidebarLeft = sidebar.offsetLeft;
  
  // Create a placeholder element to maintain space when sticky
  const placeholder = document.createElement('div');
  placeholder.style.display = 'none';
  stickyElement.parentNode.insertBefore(placeholder, stickyElement);
  
  // Use requestAnimationFrame for smooth performance
  let ticking = false;
  let isSticky = false;
  
  // Store the original position of the sticky element
  const originalOffsetTop = stickyElement.offsetTop;
  
  function updateStickyPosition() {
    if (!ticking) {
      requestAnimationFrame(() => {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        
        // Calculate the trigger point based on original position
        const triggerPoint = originalOffsetTop - 72;
        
        // Check if element should be sticky (when scrolled past trigger point)
        if (scrollTop > triggerPoint && !isSticky) {
          // Get the height before making it sticky
          const elementHeight = stickyElement.offsetHeight;
          
          // Show placeholder to maintain space
          placeholder.style.display = 'block';
          placeholder.style.height = elementHeight + 'px';
          
          // Make it sticky
          stickyElement.style.position = 'fixed';
          stickyElement.style.top = '72px';
          stickyElement.style.width = sidebarWidth + 'px';
          stickyElement.style.left = sidebarLeft + 'px';
          stickyElement.style.zIndex = '1000';
          isSticky = true;
        } else if (isSticky && scrollTop <= triggerPoint) {
          // Return to normal position
          placeholder.style.display = 'none';
          stickyElement.style.position = '';
          stickyElement.style.top = '';
          stickyElement.style.width = '';
          stickyElement.style.left = '';
          stickyElement.style.zIndex = '';
          isSticky = false;
        }
        
        ticking = false;
      });
      ticking = true;
    }
  }
  
  // Throttled scroll listener
  window.addEventListener('scroll', updateStickyPosition, { passive: true });
  
  // Also handle resize events
  window.addEventListener('resize', () => {
    // Recalculate measurements on resize
    const newSidebarWidth = sidebar.offsetWidth;
    const newSidebarLeft = sidebar.offsetLeft;
    
    if (isSticky) {
      stickyElement.style.width = newSidebarWidth + 'px';
      stickyElement.style.left = newSidebarLeft + 'px';
    }
  }, { passive: true });
}

// Try to initialize immediately
document.addEventListener('DOMContentLoaded', initializeStickyBillboard);

// Also try after a delay to catch dynamically loaded content
setTimeout(initializeStickyBillboard, 1000);
setTimeout(initializeStickyBillboard, 2000);
setTimeout(initializeStickyBillboard, 3000);

// Listen for DOM changes to catch dynamically loaded content
const observer = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
    if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
      // Check if our sticky element was added
      for (let i = 0; i < mutation.addedNodes.length; i++) {
        const node = mutation.addedNodes[i];
        if (node.nodeType === Node.ELEMENT_NODE) {
          if (node.id === 'sticky-billboard' || node.querySelector('#sticky-billboard')) {
            initializeStickyBillboard();
            return;
          }
        }
      }
    }
  });
});

// Start observing
observer.observe(document.body, {
  childList: true,
  subtree: true
});
