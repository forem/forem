function initializeProMembershipsPage() {
  const createProForm = document.getElementById('new_pro_membership');
  if (createProForm) {
    createProForm.addEventListener('submit', function onSubmit(event) {
      event.preventDefault();

      if (window.confirm('Are you sure?')) {
        // eslint-disable-line no-alert
        event.target.submit();
        return true;
      }

      return false;
    });
  }
}
