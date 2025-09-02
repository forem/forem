/**
 * Subforem Selection Modal functionality
 * Handles the modal for selecting which subforem to post to when on root subforem
 */

(function() {
  // Subforem Selection Modal functionality
  const modal = document.getElementById('subforem-selection-modal');
  if (!modal) return;

  const backdrop = modal.querySelector('.subforem-modal__backdrop');
  const closeButton = modal.querySelector('.subforem-modal__close');

  // Function to open modal
  function openModal() {
    modal.classList.remove('hidden');
    document.body.style.overflow = 'hidden';
    modal.focus();
  }

  // Function to close modal
  function closeModal() {
    modal.classList.add('hidden');
    document.body.style.overflow = '';
  }

  // Event listeners
  if (backdrop) {
    backdrop.addEventListener('click', closeModal);
  }

  if (closeButton) {
    closeButton.addEventListener('click', closeModal);
  }

  // Handle escape key
  document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && !modal.classList.contains('hidden')) {
      closeModal();
    }
  });

  // Expose openModal function globally so it can be called from buttons
  window.openSubforemModal = openModal;
})();
