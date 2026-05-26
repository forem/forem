/**
 * Custom smooth scroll to an element with a specified duration.
 * @param {HTMLElement} element - The target element to scroll to.
 * @param {number} duration - The duration of the scroll animation in milliseconds.
 * @param {number} offset - The offset from the top of the element.
 */
export const smoothScrollTo = (element, duration = 400, offset = 0) => {
    if (!element) return;

    const targetPosition = element.getBoundingClientRect().top + window.pageYOffset - offset;
    const startPosition = window.pageYOffset;
    const distance = targetPosition - startPosition;
    let startTime = null;

    function easeInOutQuad(t, b, c, d) {
        t /= d / 2;
        if (t < 1) return (c / 2) * t * t + b;
        t--;
        return (-c / 2) * (t * (t - 2) - 1) + b;
    }

    function animation(currentTime) {
        if (startTime === null) startTime = currentTime;
        const timeElapsed = currentTime - startTime;
        const scrollAmount = easeInOutQuad(
            timeElapsed,
            startPosition,
            distance,
            duration,
        );

        window.scrollTo(0, scrollAmount);

        if (timeElapsed < duration) {
            requestAnimationFrame(animation);
        } else {
            window.scrollTo(0, targetPosition);
        }
    }

    requestAnimationFrame(animation);
};
