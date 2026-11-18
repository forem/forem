import { initializeSandboxedEmbeds } from '../utilities/pageEmbedWrapper';
import { initializeEmbedEditorPreviews } from '../utilities/embedEditorPreview';

function bootSandboxedEmbeds(root = document) {
  initializeSandboxedEmbeds(root);
  initializeEmbedEditorPreviews(root);
}

globalThis.__foremInitSandboxedEmbeds = bootSandboxedEmbeds;
globalThis.__foremInitEmbedEditors = initializeEmbedEditorPreviews;
bootSandboxedEmbeds(document);
