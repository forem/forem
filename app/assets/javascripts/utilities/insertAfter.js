function insertAfter(newNode, referenceNode) {
    if (referenceNode && referenceNode.parentNode){
      referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
    }
}
