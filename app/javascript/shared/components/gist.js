import postscribe from 'postscribe';

export function embedGists() {
    const els = document.getElementsByClassName('ltag_gist-liquid-tag');
    for (let i = 0; i < els.length; i += 1) {
        postscribe(els[i], els[i].firstElementChild.outerHTML);
    }
}
