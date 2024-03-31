function assertions(_chai, _utils) {
  _chai.Assertion.addMethod('within_viewport', function withinViewport() {
    const elements = this._obj;

    cy.window().then((window) => {
      const viewportRight = window.innerWidth;
      const viewportBottom = window.innerHeight;

      const bounds = elements[0].getBoundingClientRect();

      this.assert(
        bounds.top < viewportBottom &&
          bounds.bottom > 0 &&
          bounds.left < viewportRight &&
          bounds.right > 0,
        'expected #{this} to be within the viewport',
        'expected #{this} to not be within the viewport',
        this._obj,
      );
    });
  });
}

chai.use(assertions);
