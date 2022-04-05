import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';
/**
 * Responsible for hiding or showing elements that match each of the given user
 * policies.  While this function is "oblivious" to what it's hiding, it
 * coordinates between the rendered HTML and the user data to show or hide
 * elements that present functionality available or not available to the given
 * user.
 *
 * A critical assumption is that we are not employing "security through
 * obscurity".  That is to say, if we accidentally show the link, the server
 * will enforce the correct policy.
 */
getUserDataAndCsrfToken().then(({ currentUser }) => {
  if (currentUser.policies) {
    currentUser.policies.forEach((policy) => {
      const elements = document.getElementsByClassName(policy.dom_class);
      for (const element of elements) {
        if (policy.visible) {
          element.classList.remove('hidden');
        } else {
          element.classList.add('hidden');
        }
      }
    });
  }
});
