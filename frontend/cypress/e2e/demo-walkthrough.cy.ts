/// <reference types="cypress" />

const capitolHillStory = "A little more room to linger on Pike Street";
const ballardStory = "A neighborhood table at the Ballard market";
const ballardComment =
  "A shared table would make it easier to meet the people behind the stalls.";

// One release-blocking journey, repeated at desktop and mobile sizes in fresh
// guest sessions. No network stubs: fixtures must come from the shipped app.
describe("Portfolio walkthrough", () => {
  it("switches neighborhoods, replaces the stories, and opens the seeded discussion", () => {
    for (const viewport of [
      { name: "desktop", width: 1440, height: 1000 },
      { name: "mobile", width: 390, height: 844 },
    ]) {
      cy.viewport(viewport.width, viewport.height);
      cy.clearCookies();
      cy.clearLocalStorage();
      cy.visit("/", {
        onBeforeLoad(win) {
          win.sessionStorage.clear();
          win.localStorage.clear();
        },
      });

      cy.contains(/fictional/i).should("be.visible");
      if (viewport.name === "desktop") {
        cy.contains("Explore Seattle Pulse").should("be.visible");
      }
      cy.get('[aria-label="Choose neighborhood"]')
        .should("be.visible")
        .and("contain.text", "Capitol Hill");
      cy.contains('[data-cy="post-card"]', capitolHillStory).should("be.visible");
      cy.get('[data-cy="post-card"]').each(($card) => {
        cy.wrap($card).should("contain.text", "Capitol Hill, Seattle");
      });
      cy.contains('[data-cy="post-card"]', ballardStory).should("not.exist");
      cy.get('[data-cy="post-card"] img').should(($images) => {
        for (const image of $images.toArray() as HTMLImageElement[]) {
          expect(image.complete && image.naturalWidth > 0, image.src).to.equal(true);
        }
      });
      // Freezing timers while capturing can trip React 19 scheduling invariants.
      cy.screenshot(`demo-${viewport.name}-feed`, { capture: "viewport", disableTimersAndAnimations: false });

      cy.get('[aria-label="Choose neighborhood"]').click();
      cy.contains('[role="menuitem"]', /^Ballard, Seattle$/).click();
      cy.get('[aria-label="Choose neighborhood"]').should("contain.text", "Ballard");
      cy.contains('[data-cy="post-card"]', ballardStory).should("be.visible");
      cy.contains('[data-cy="post-card"]', capitolHillStory).should("not.exist");
      cy.get('[data-cy="post-card"]').each(($card) => {
        cy.wrap($card).should("contain.text", "Ballard, Seattle");
      });

      cy.contains('[data-cy="post-card"]', ballardStory)
        .find('[data-cy="open-discussion"]')
        .click();
      cy.get('[data-cy="demo-discussion"]').should("be.visible").and("have.css", "opacity", "1").within(() => {
        cy.contains(ballardStory).should("be.visible");
        cy.contains(ballardComment).should("be.visible");
        cy.get("img").should(($images) => {
          for (const image of $images.toArray() as HTMLImageElement[]) {
            expect(image.complete && image.naturalWidth > 0, image.src).to.equal(true);
          }
        });
      });
      cy.window().then((win) => {
        const resources = win.performance.getEntriesByType("resource")
          .map((entry) => new URL(entry.name, win.location.href));
        expect(resources.filter((url) => url.origin !== win.location.origin).map((url) => url.href),
          "all scripts, images, fonts, and requests use the demo origin").to.deep.equal([]);
        expect(resources.filter((url) => url.pathname.startsWith("/api/") || url.pathname.startsWith("/socket.io")).map((url) => url.href),
          "no backend or socket requests in the reading demo").to.deep.equal([]);
      });
      cy.screenshot(`demo-${viewport.name}-discussion`, { capture: "viewport", disableTimersAndAnimations: false });
    }
  });
});
