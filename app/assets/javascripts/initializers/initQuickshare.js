function QSFBEmbedParse(timeout = 2000) {
    setTimeout(() => {
        const fbPostNotRendered = document.querySelectorAll('.fb-post:not([fb-xfbml-state="rendered"])');
        const fbVideoNotRendered = document.querySelectorAll('.fb-video:not([fb-xfbml-state="rendered"])');
        if (fbPostNotRendered.length || fbVideoNotRendered.length) {
            // eslint-disable-next-line no-undef
            FB.XFBML.parse();
        }
    }, timeout);
}