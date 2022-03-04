import { embedGists } from '../utilities/gist';

const targetNode = document.querySelector('#comments-container');
targetNode && embedGists(targetNode);
