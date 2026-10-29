# Cogniti Research

This Obsidian vault is published with GitHub Pages at https://cogniti-research.github.io/test/. Every push to `master` rebuilds the site within a minute or two; the Actions tab shows each "pages build and deployment" run.

## How the site is put together

- `index.md` is the home page. Each theme is a `##` heading, a one-line description, then one card per study.
- `Summary of Cogniti Empirical studies/Summary of Cogniti Empirical studies.md` is published at `/summary/` (set by `permalink` in its front matter). Its sidebar contents list is built automatically from the `##` themes and `###` studies.
- `_layouts/` and `assets/` hold the page templates, styles and script. `_config.yml` holds the site title, description and header links.

## Adding a study

Add it to the summary note under the right `##` theme as a `###` heading with the full citation, starting with the first author's surname, e.g. `### Smith, J., & Lee, K. (2026). Title...`.

On a computer with the index hook set up (below), the next commit adds a card for it to `index.md`. The card's title, authors and venue are worked out from the citation, so check the new card and tidy its wording in `index.md` if needed. Your edits are kept: the hook only adds cards for new studies, removes cards for deleted ones and keeps the order in step with the summary. Theme names and descriptions in `index.md` are kept as you write them too, and a new theme starts with its heading from the summary and no description.

Each card links to `summary/#` plus the first author's surname and the year in lower case, e.g. `summary/#smith-2026`. If two studies share a surname and year, the second one gets `-2` on the end. The study counts on the home page update themselves.

## Setting up the index hook

Do this once on each computer that edits the vault. It needs nothing installed beyond Git, which Obsidian Git already uses, and the PowerShell that comes with Windows.

1. Open PowerShell in the vault folder. On Windows 11, right-click the folder in File Explorer and choose "Open in Terminal"; otherwise open PowerShell from the Start menu and run `cd "<path to the vault>"`.
2. Run `git config core.hooksPath scripts/hooks`.

From then on, every commit (including Obsidian Git's automatic backups) runs `scripts/Update-Index.ps1` first. If the script fails, the commit still goes ahead without updating `index.md`. To rebuild the index by hand, run `powershell -ExecutionPolicy Bypass -File scripts/Update-Index.ps1`.

## Links and Obsidian

GitHub Pages doesn't understand Obsidian `[[wikilinks]]`, so use standard Markdown links in published notes. In Obsidian, go to Settings > Files and links, turn off "Use [[Wikilinks]]" and set "New link format" to "Relative path to file".

Links between notes are converted to page links automatically, as long as the file path has no spaces. For a note whose path has spaces, add a `permalink` to its front matter and link to that URL instead, as the home page does with `summary/`.
