// Store subforem ID in localStorage when user visits signup page
document.addEventListener('DOMContentLoaded', () => {
  const urlParams = new URLSearchParams(window.location.search);
  const signupSubforem = urlParams.get('signup_subforem');
  
  if (signupSubforem) {
    localStorage.setItem('signup_subforem_id', signupSubforem);
  }
});
