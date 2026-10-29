(function () {
  const slugify = (text) => text.toLowerCase().normalize("NFKD").replace(/[^\w\s-]/g, "").trim().replace(/[\s_]+/g, "-");

  // Study headings are full citations, so Jekyll's generated IDs are very long and change
  // whenever a citation is edited. Give each one a short anchor: first author's surname and
  // year, e.g. "Espinosa, H. G., ... (2025)" becomes #espinosa-2025.
  // scripts/Update-Index.ps1 builds the home page links the same way; keep the two in step.
  function shortStudyId(heading) {
    const text = heading.textContent;
    const surname = text.split(",")[0];
    const yearMatch = text.match(/\((\d{4})/);
    return {
      id: slugify(surname + (yearMatch ? "-" + yearMatch[1] : "")),
      label: surname.trim() + (yearMatch ? " (" + yearMatch[1] + ")" : "")
    };
  }

  function buildSummaryContents() {
    const tocList = document.getElementById("toc-list");
    if (!tocList) {
      return;
    }

    const usedIds = new Set();
    const themes = document.createElement("ol");
    let currentStudies = null;

    document.querySelectorAll(".content h2, .content h3").forEach((heading) => {
      if (heading.tagName === "H2") {
        const item = document.createElement("li");
        item.innerHTML = '<a href="#' + heading.id + '"></a>';
        item.firstChild.textContent = heading.textContent;
        currentStudies = document.createElement("ol");
        item.appendChild(currentStudies);
        themes.appendChild(item);
      } else {
        const study = shortStudyId(heading);
        let id = study.id;
        for (let suffix = 2; usedIds.has(id); suffix++) {
          id = study.id + "-" + suffix;
        }
        usedIds.add(id);
        heading.id = id;

        if (currentStudies) {
          const item = document.createElement("li");
          item.innerHTML = '<a href="#' + id + '"></a>';
          item.firstChild.textContent = study.label;
          currentStudies.appendChild(item);
        }
      }
    });

    tocList.appendChild(themes);

    // On narrow screens the contents sit above the article, so start them collapsed.
    if (window.matchMedia("(max-width: 900px)").matches) {
      tocList.closest("details").open = false;
    }

    // The short IDs did not exist when the browser first looked for the URL's #anchor.
    if (location.hash) {
      const target = document.getElementById(decodeURIComponent(location.hash.slice(1)));
      if (target) {
        target.scrollIntoView();
      }
    }
  }

  function buildHomeThemes() {
    const chips = document.getElementById("theme-chips");
    if (!chips) {
      return;
    }

    const themeHeadings = document.querySelectorAll(".home-content h2");
    let studyCount = 0;

    themeHeadings.forEach((heading) => {
      let list = heading.nextElementSibling;
      while (list && list.tagName !== "UL" && list.tagName !== "H2") {
        list = list.nextElementSibling;
      }
      const count = list && list.tagName === "UL" ? list.children.length : 0;
      studyCount += count;

      const badge = document.createElement("span");
      badge.className = "count";
      badge.textContent = count === 1 ? "1 study" : count + " studies";
      heading.appendChild(badge);

      const chip = document.createElement("a");
      chip.href = "#" + heading.id;
      chip.textContent = heading.firstChild.textContent.trim();
      chips.appendChild(chip);
    });

    chips.hidden = themeHeadings.length === 0;

    const stats = document.getElementById("hero-stats");
    if (stats && studyCount > 0) {
      stats.textContent = studyCount + " studies across " + themeHeadings.length + " themes";
      stats.hidden = false;
    }
  }

  buildSummaryContents();
  buildHomeThemes();
})();
