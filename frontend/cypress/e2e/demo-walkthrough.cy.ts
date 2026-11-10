/// <reference types="cypress" />

const marketStory = "A slower way through Pike Place Market";
const capitolHillStory = "An hour at Cal Anderson Park";
const ballardStory = "A walk through the Ballard Locks";
const ballardComment = "The view from the fish ladder is worth the extra few minutes.";
const localComment = "Saving this walk for the weekend.";
const openedSockets: string[] = [];

function loadedImages(selector: string) {
  cy.get(selector).should(($images) => {
    expect($images.length, "images are rendered").to.be.greaterThan(0);
    for (const image of $images.toArray() as HTMLImageElement[]) {
      expect(image.complete && image.naturalWidth > 0, image.src).to.equal(true);
    }
  });
}

function onlyLocalResources() {
  cy.then(() => expect(openedSockets, "no WebSocket connections in the static demo").to.deep.equal([]));
  cy.window().then((win) => {
    const resources = win.performance.getEntriesByType("resource")
      .map((entry) => new URL(entry.name, win.location.href));
    expect(resources.filter((url) => url.origin !== win.location.origin).map((url) => url.href),
      "all runtime resources use the demo origin").to.deep.equal([]);
    expect(resources.filter((url) => url.pathname.startsWith("/api/") || url.pathname.startsWith("/socket.io")).map((url) => url.href),
      "no live backend or socket requests").to.deep.equal([]);
  });
}

function activeDestination(name: string, path: RegExp) {
  cy.location("pathname").should("match", path);
  cy.get('[data-cy="demo-nav"] a[aria-current="page"]').filter(":visible")
    .should(($links) => {
      expect($links.toArray().map(link => link.textContent?.trim()), "exactly the current destination is active").to.deep.equal([name]);
    });
}

function navigate(name: string, path: RegExp) {
  cy.get('[data-cy="demo-nav"] a').filter(":visible").contains(name).click();
  activeDestination(name, path);
}

function signInLink() {
  return cy.get('a[href="/auth/login"], a[href="/auth/login/"]').filter(":visible").first();
}

function openBallardDiscussion() {
  cy.contains('[data-cy="post-card"]', ballardStory).find('[data-cy="open-discussion"]').click();
  cy.get('[data-cy="demo-discussion"]').should("be.visible").and("have.css", "opacity", "1").within(() => {
    cy.contains(ballardStory).should("be.visible");
    cy.contains(ballardComment).should("be.visible");
    cy.get('[data-cy="discussion-publisher"]').should("contain.text", "Ballard Notes");
    cy.get('[data-cy="discussion-publisher"] img').should("have.attr", "src", "/demo/publishers/9201.svg");
    loadedImages("img");
  });
}

function closeDiscussion() {
  cy.get('[data-cy="demo-discussion"]').find('button').filter((_, element) => element.textContent?.trim() === "Close").click();
  cy.get('[data-cy="demo-discussion"]').should("not.exist");
}

// One release-blocking journey, repeated in fresh guest sessions at both sizes.
// No API stubs: the exported application owns the fixtures and browser-local state.
describe("Browsable portfolio product", () => {
  it("browses Seattle, signs in, follows sources, and reloads real product routes", () => {
    openedSockets.length = 0;
    cy.on("window:before:load", win => {
      const NativeWebSocket = win.WebSocket;
      win.WebSocket = new Proxy(NativeWebSocket, {
        construct(target, args, receiver) {
          openedSockets.push(String(args[0]));
          return Reflect.construct(target, args, receiver);
        },
      });
    });
    for (const viewport of [
      { name: "desktop", width: 1440, height: 1000 },
      { name: "mobile", width: 390, height: 844 },
    ]) {
      const publisherImages: Record<string, string> = {};
      cy.viewport(viewport.width, viewport.height);
      cy.clearCookies();
      cy.clearLocalStorage();
      cy.visit("/", {
        onBeforeLoad(win) {
          win.sessionStorage.clear();
          win.localStorage.clear();
        },
      });

      cy.get('[data-cy="demo-disclosure"]').should("be.visible");
      activeDestination("The Feed", /^\/$/);
      cy.get('[aria-label="Choose neighborhood"]').should("contain.text", "All Seattle");
      cy.get('[data-cy="post-card"]').should("have.length", 8);
      cy.get('[aria-label="About this demo"]').should("not.exist");
      cy.contains("Seattle, block by block.").should("not.exist");
      cy.get('[data-cy="post-card"]').first().find('[data-cy="open-discussion"]')
        .should("be.visible").and(($title) => {
          const bounds = $title[0].getBoundingClientRect();
          expect(bounds.top, "first story starts in the initial viewport").to.be.at.least(0);
          expect(bounds.bottom, "first story title fits above the fold").to.be.at.most(viewport.height);
        });
      cy.get('[data-cy="post-card"]').then(($cards) => {
        const areas = $cards.toArray().map(card => card.textContent?.match(/(?:Downtown|Capitol Hill|Ballard|U District|Wallingford|West Seattle|Queen Anne|Seward Park), Seattle/)?.[0]);
        expect(new Set(areas).size, "eight distinct Seattle areas").to.equal(8);
        expect(areas).not.to.include(undefined);
      });
      cy.contains('[data-cy="post-card"]', marketStory).should("exist");
      cy.contains('[data-cy="post-card"]', capitolHillStory).should("exist");
      cy.contains('[data-cy="post-card"]', ballardStory).should("exist");
      cy.get('[data-cy="post-card"]').each(($card) => {
        cy.wrap($card).find("h3").invoke("text").then(name => {
          cy.wrap($card).find(`img[alt="${name.trim()}"]`).should(($images) => {
            const image = $images[0] as HTMLImageElement;
            expect(image.complete && image.naturalWidth > 0, `${name} publisher image`).to.equal(true);
            publisherImages[name.trim()] = image.src;
          });
        });
      });
      cy.then(() => expect(new Set(Object.values(publisherImages)).size, "distinct bundled publisher identities").to.equal(8));
      loadedImages('[data-cy="post-card"]:first img[src$=".webp"]');
      onlyLocalResources();
      cy.screenshot(`demo-${viewport.name}-feed`, { capture: "viewport", disableTimersAndAnimations: false });

      cy.get('[aria-label="Choose neighborhood"]').click();
      cy.contains('[role="menuitem"]', /^Ballard, Seattle$/).click();
      cy.get('[data-cy="post-card"]').should("have.length", 1);
      cy.contains('[data-cy="post-card"]', ballardStory).should("be.visible");
      cy.contains('[data-cy="post-card"]', capitolHillStory).should("not.exist");
      openBallardDiscussion();
      closeDiscussion();

      signInLink().click();
      cy.location("pathname").should("match", /^\/auth\/login\/?$/);
      cy.get('[style*="bg-up.png"]').should("be.visible");
      cy.window().then((win) => {
        const artwork = new win.Image();
        artwork.src = new URL("/bg-up.png", win.location.href).href;
        return artwork.decode();
      });
      loadedImages('img[alt="Seattle Pulse"]');
      cy.contains("button", "Continue as demo reader").should("be.visible");
      cy.screenshot(`demo-${viewport.name}-sign-in`, { capture: "viewport", disableTimersAndAnimations: false });
      onlyLocalResources();
      cy.contains("a", "Back to browsing").click();
      activeDestination("The Feed", /^\/$/);
      cy.get('[aria-label="Choose neighborhood"]').should("contain.text", "Ballard");
      signInLink().click();
      cy.contains("button", "Continue as demo reader").click();
      activeDestination("The Feed", /^\/$/);
      cy.get('[aria-label="Choose neighborhood"]').should("contain.text", "Ballard");
      cy.contains('[data-cy="post-card"]', ballardStory).should("be.visible");
      openBallardDiscussion();
      cy.get("#demo-comment").type(localComment);
      cy.contains("button", "Add demo comment").click();
      cy.contains(localComment).scrollIntoView().should("be.visible");
      closeDiscussion();

      navigate("My Pulse", /^\/mypulse\/?$/);
      cy.get('[data-cy="post-card"]').should("have.length", 3);
      cy.contains('[data-cy="post-card"]', marketStory).should("exist");
      cy.contains('[data-cy="post-card"]', capitolHillStory).should("exist");
      cy.contains('[data-cy="post-card"]', ballardStory).should("exist");
      cy.contains('[data-cy="post-card"]', "The long way along Alki").should("not.exist");
      cy.get('[data-cy="post-card"] img').each(($image) => {
        const image = $image[0] as HTMLImageElement;
        if (publisherImages[image.alt]) expect(image.src, `${image.alt} consistent image`).to.equal(publisherImages[image.alt]);
      });
      cy.screenshot(`demo-${viewport.name}-my-pulse`, { capture: "viewport", disableTimersAndAnimations: false });
      if (viewport.name === "mobile") cy.contains("summary", "Manage sources").click();
      cy.get('[data-cy="follow-source-9101"]').eq(viewport.name === "mobile" ? 0 : 1).scrollIntoView().should("have.attr", "aria-pressed", "true").click();
      cy.get('[data-cy="post-card"]').should("have.length", 2);
      cy.contains('[data-cy="post-card"]', marketStory).should("not.exist");
      cy.reload();
      activeDestination("My Pulse", /^\/mypulse\/?$/);
      cy.get('[data-cy="post-card"]').should("have.length", 2);
      cy.contains('[data-cy="post-card"]', marketStory).should("not.exist");
      if (viewport.name === "mobile") cy.contains("summary", "Manage sources").click();
      cy.get('[data-cy="follow-source-9101"]').eq(viewport.name === "mobile" ? 0 : 1).scrollIntoView().should("have.attr", "aria-pressed", "false").click();
      cy.get('[data-cy="post-card"]').should("have.length", 3);
      onlyLocalResources();

      navigate("Profile", /^\/profile\/?$/);
      cy.get('[data-cy="demo-profile"]').should("contain.text", "Alex Morgan");
      loadedImages('[data-cy="demo-profile"] img[alt="Profile picture"]');
      cy.get('[data-cy="profile-content"] img').should("have.length.greaterThan", 0);
      loadedImages('[data-cy="profile-content"] img');
      cy.get('[data-cy="profile-content"] img').each(($image) => {
        const image = $image[0] as HTMLImageElement;
        if (publisherImages[image.alt]) expect(image.src, `${image.alt} consistent profile image`).to.equal(publisherImages[image.alt]);
      });
      cy.screenshot(`demo-${viewport.name}-profile`, { capture: "viewport", disableTimersAndAnimations: false });
      cy.contains('[data-cy="saved-guide"]', ballardStory).click();
      cy.get('[data-cy="demo-discussion"]').should("contain.text", localComment);
      closeDiscussion();
      cy.contains('[role="tab"]', "Your comments").click().should("have.attr", "aria-selected", "true");
      cy.get('[role="tabpanel"]').should("contain.text", localComment);
      cy.contains('[role="tabpanel"] button', ballardStory).click();
      cy.get('[data-cy="demo-discussion"]').should("contain.text", localComment);
      closeDiscussion();
      cy.contains('[role="tab"]', "Saved guides").click().should("have.attr", "aria-selected", "true");
      cy.get("button").filter(":visible").contains("Edit Profile").click();
      cy.contains("Edit your demo profile").should("be.visible");
      cy.get("#demo-bio").clear().type("Finding a new Seattle walk each weekend. Fictional demo reader.");
      cy.contains("button", "Save changes").click();
      cy.contains("Profile updated in this demo session.").should("be.visible");
      cy.reload();
      activeDestination("Profile", /^\/profile\/?$/);
      cy.get('[data-cy="demo-profile"]').should("contain.text", "Alex Morgan")
        .and("contain.text", "Finding a new Seattle walk each weekend. Fictional demo reader.");
      onlyLocalResources();

      // Hard navigation proves these are exported, refreshable URLs, not view toggles.
      for (const route of ["/", "/auth/login/", "/mypulse/", "/profile/"]) cy.request(route).its("status").should("equal", 200);
      cy.visit("/mypulse/");
      activeDestination("My Pulse", /^\/mypulse\/?$/);
      cy.get('[data-cy="post-card"]').should("have.length", 3);
      navigate("The Feed", /^\/$/);
      cy.get('[aria-label="Choose neighborhood"]').should("contain.text", "Ballard");
      openBallardDiscussion();
      cy.contains(localComment).scrollIntoView().should("be.visible");
      onlyLocalResources();
      cy.get('[data-cy="demo-discussion"]').scrollTo("top", { ensureScrollable: false });
      cy.screenshot(`demo-${viewport.name}-discussion`, { capture: "viewport", disableTimersAndAnimations: false });
      closeDiscussion();
      cy.get("button").filter(":visible").contains(/^Sign out$/).click();
      signInLink().should("be.visible");
      navigate("Profile", /^\/profile\/?$/);
      cy.contains("a", "Sign in to try Profile").should("be.visible");
      cy.get('[data-cy="profile-content"]').should("not.exist");
      cy.reload();
      cy.contains("a", "Sign in to try Profile").should("be.visible");
      onlyLocalResources();
    }
  });
});
