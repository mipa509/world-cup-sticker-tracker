# World Cup Sticker Tracker

Standalone mobile-first sticker tracker for the 2026 World Cup album.

## Live app
Open the app here:

https://mipa509.github.io/world-cup-sticker-tracker/

On iPhone, open the link in Safari and use Share > Add to Home Screen for the best app-like experience.

## What it does
- Track owned, needed, and swap stickers for all 48 World Cup 2026 teams.
- Use the matrix grid for a quick album overview.
- Export the matrix as a PNG for sharing in chats or Facebook groups.
- Export/copy your current swap list.
- Match trades by entering another person's needs and swaps.
- Save proposed trades so agreed swaps are reserved automatically.

## Trade workflow
Use `They need` and `They swap` in the Trade Matcher, choose a team, and tap sticker numbers. The app shows what you can give and receive.

When you click `Save Trade`, the stickers you are giving are reserved. Reserved stickers no longer appear in your available swap list or future trade matches, so the next person only sees what is still available. Deleting a saved trade releases those swaps again.

Saved trades can be copied, loaded back into the matcher, deleted, and included in JSON backups.

## Can other people use it?
Yes. Anyone can open the public app link and track their own album.

Each person's sticker data stays in their own browser using `localStorage`. The app does not upload collections to GitHub, does not share your data with me, and does not use a shared database.

That means:

- Your collection is separate from everyone else's collection.
- A friend can use the same public link and have their own data on their own phone.
- If someone clears Safari/browser data, their saved collection may be removed.
- To back up or move phones, use `Export` to save a JSON file, then `Import` it later.
- JSON backups include your album state and any saved trade proposals.

## Suggested sharing text
Track your World Cup 2026 sticker album, swaps, needs, and trade matches here:

https://mipa509.github.io/world-cup-sticker-tracker/

Open it in Safari/Chrome and add it to your home screen. Your data is stored only on your own device. Use Export/Import JSON for backup or moving between devices.

## Use locally
Open `index.html` in a browser, or serve the folder with any static file server.

## Publish your own copy
You can fork this repository or copy the files into your own GitHub repository and enable GitHub Pages.

1. Fork or create a new empty repository, for example `world-cup-sticker-tracker`.
2. Push `index.html`, `README.md`, and `.gitignore`.
3. In GitHub: Settings > Pages > Build and deployment > Deploy from a branch > `main` / root.

The app stores sticker data and saved trade proposals in the browser using `localStorage`. Use Export/Import JSON to move data between devices until cloud sync is added.
