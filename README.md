# Cogniti Research

This Obsidian vault is published with GitHub Pages at https://cogniti-research.github.io/test/. Every push to `master` rebuilds the site within a minute or two; the Actions tab shows each "pages build and deployment" run.

## How the site is put together

- `index.md` is the home page. Each theme is a `##` heading, a one-line description, then one card per study.
- `Summary of Cogniti Empirical studies/Summary of Cogniti Empirical studies.md` is published at `/summary/` (set by `permalink` in its front matter). Its sidebar contents list is built automatically from the `##` themes and `###` studies.
- `_layouts/` and `assets/` hold the page templates, styles and script. `_config.yml` holds the site title, description and header links.

## Adding a study

1. Add it to the summary note under the right `##` theme as a `###` heading with the full citation, starting with the first author's surname, e.g. `### Smith, J., & Lee, K. (2026). Title...`.
2. Add a card to `index.md` under the same theme:

   ```markdown
   - [Title of the study](summary/#smith-2026)
     Smith & Lee (2026) · Journal or venue
   ```

   The anchor after `#` is the first author's surname and the year in lower case. If two studies share a surname and year, the second one gets `-2` on the end.

The study counts on the home page update themselves.

## Links and Obsidian

GitHub Pages doesn't understand Obsidian `[[wikilinks]]`, so use standard Markdown links in published notes. In Obsidian, go to Settings > Files and links, turn off "Use [[Wikilinks]]" and set "New link format" to "Relative path to file".

Links between notes are converted to page links automatically, as long as the file path has no spaces. For a note whose path has spaces, add a `permalink` to its front matter and link to that URL instead, as the home page does with `summary/`.
