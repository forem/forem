function getCurrentPage(classString) {
    return document.querySelectorAll("[data-current-page='"+classString+"']").length > 0
}