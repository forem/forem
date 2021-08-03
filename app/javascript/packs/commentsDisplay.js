import { embedGists } from '../utilities/gist';

const targetNode = document.querySelector('.comment-form');
targetNode && embedGists(targetNode);
