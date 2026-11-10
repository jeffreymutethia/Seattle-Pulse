const commons = "https://commons.wikimedia.org/wiki/File:";
const cc = "https://creativecommons.org/licenses/";

export const demoPhotography = {
  "seattle-skyline": ["Downtown Seattle and Mount Rainier from Kerry Park 2013-03-09.jpg", "Velkiira / Evelyn Wu", "by-sa/2.0"],
  "pike-place": ["Pike Place Market Seattle.jpg", "Daniel Schwen", "by-sa/4.0"],
  "cal-anderson": ["Cal Anderson Park 02.jpg", "Joe Mabel", "by-sa/3.0"],
  "ballard-locks": ["Ballard (Hiram M. Chittenden) Locks.jpg", "SEAotter206", "by/4.0"],
  "uw-quad": ["Cherry Blossoms on UW Quad - Flickr - brewbooks (1).jpg", "brewbooks", "by-sa/2.0"],
  "gas-works": ["Gas works from the hill 01.jpg", "Cody Logan", "by-sa/4.0"],
  "seward-park": ["Aerial view of Seward Park, Seattle.jpg", "Dcoetzee", "public-domain"],
  alki: ["Alki Beach 2.jpg", "Joe Mabel", "by-sa/3.0"],
} as const;

export function photoCredit(key: keyof typeof demoPhotography) {
  const [title, author, license] = demoPhotography[key];
  const publicDomain = license === "public-domain";
  return {
    title,
    author,
    source: commons + encodeURIComponent(title.replaceAll(" ", "_")),
    license: publicDomain ? "Public domain" : "CC " + license.toUpperCase().replace("/", " "),
    licenseUrl: publicDomain ? "https://creativecommons.org/publicdomain/mark/1.0/" : cc + license + "/",
  };
}
