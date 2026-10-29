<#
.SYNOPSIS
Brings the study cards in index.md into line with the summary note.

.DESCRIPTION
Reads the theme (##) and study (###) headings in the summary note, then updates index.md:
- adds a card for each new study, with its title, authors, year and venue taken from the citation,
- removes cards for studies that are no longer in the summary,
- puts themes and cards in the same order as the summary.

Everything already in index.md is kept as written: the front matter, theme names and descriptions, and
the wording of existing cards. Tidy a new card's wording in index.md once and later runs leave it alone.

Card links use the short anchors that assets/js/site.js gives each study on the summary page (first
author's surname and year, e.g. #espinosa-2025). Get-StudyAnchor must stay in step with shortStudyId there.

Runs from the pre-commit hook in scripts/hooks, and works in Windows PowerShell 5.1 and PowerShell 7.
#>
param(
    [string]$SummaryPath = (Join-Path $PSScriptRoot "../Summary of Cogniti Empirical studies/Summary of Cogniti Empirical studies.md"),
    [string]$IndexPath = (Join-Path $PSScriptRoot "../index.md")
)

$ErrorActionPreference = "Stop"

# .NET file calls resolve relative paths against the process directory, so pass them full paths.
$SummaryPath = (Resolve-Path -LiteralPath $SummaryPath).Path
$IndexPath = (Resolve-Path -LiteralPath $IndexPath).Path

$SummaryUrl = "summary/"

function Read-TextLines([string]$path) {
    # ReadAllText reads UTF-8 with or without a BOM; Get-Content in PowerShell 5.1 would assume ANSI.
    $text = [System.IO.File]::ReadAllText($path)
    return , ($text -replace "`r`n", "`n" -split "`n")
}

# Matches what a browser shows for a heading: link text without its URL, no escapes or emphasis markers.
function ConvertTo-PlainText([string]$markdown) {
    $text = $markdown -replace '\[([^\]]*)\]\([^)]*\)', '$1'
    $text = $text -replace '\\(.)', '$1'
    $text = $text -replace '\*', ''
    $text = $text -replace '(?<![A-Za-z0-9])_|_(?![A-Za-z0-9])', ''
    return $text.Trim()
}

# Same steps as slugify in assets/js/site.js.
function ConvertTo-Slug([string]$text) {
    $slug = $text.ToLowerInvariant().Normalize([System.Text.NormalizationForm]::FormKD)
    $slug = $slug -creplace '[^a-z0-9_\s-]', ''
    return ($slug.Trim() -creplace '[\s_]+', '-')
}

# Same steps as shortStudyId in assets/js/site.js: "Espinosa, H. G., ... (2025)" becomes espinosa-2025.
function Get-StudyAnchor([string]$plainHeading) {
    $surname = $plainHeading.Split(",")[0]
    $yearMatch = [regex]::Match($plainHeading, '\((\d{4})')
    if ($yearMatch.Success) {
        return ConvertTo-Slug ($surname + "-" + $yearMatch.Groups[1].Value)
    }
    return ConvertTo-Slug $surname
}

# "Espinosa, H. G., Whale, S., & Selvan, K. T." becomes "Espinosa, Whale & Selvan".
function Format-Authors([string]$authors) {
    $surnames = @($authors -replace '&', ',' -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -cnotmatch '^(?:[A-Z]\.\s*-?\s*)+$' })
    if ($surnames.Count -eq 0) {
        return $authors.Trim()
    }
    if ($surnames.Count -eq 1) {
        return $surnames[0]
    }
    if ($surnames.Count -gt 4) {
        return $surnames[0] + " et al."
    }
    return ($surnames[0..($surnames.Count - 2)] -join ", ") + " & " + $surnames[-1]
}

# Picks a short venue out of the text after the title, e.g. "AAEE 2025" or "Journal of Chemical Education".
function Format-Venue([string]$venue, [string]$year) {
    $venue = $venue -creplace '^\[[^\]]*\]\.?\s*', ''
    $venue = $venue -creplace '^In\s+', ''
    $venue = $venue -creplace '^.*?\(Eds?\.\),\s*', ''
    if ($venue -match '^https?:') {
        return ""
    }

    $acronym = [regex]::Match($venue, '\((?<name>[A-Z]{3,}[A-Za-z]*)(?:\s(?<year>\d{4}))?\)')
    if ($acronym.Success) {
        $acronymYear = $acronym.Groups["year"].Value
        if (-not $acronymYear) {
            $acronymYear = $year
        }
        return $acronym.Groups["name"].Value + " " + $acronymYear
    }

    # Stop at the first sentence end (not an initial like "S."), bracket, or ", 17(2)" / ", advance online".
    $end = [regex]::Match($venue, '(?<!\b[A-Z])\.(\s|$)|\s\(|,\s+(?=[0-9a-z])')
    if ($end.Success) {
        $venue = $venue.Substring(0, $end.Index)
    }
    return $venue.Trim().TrimEnd(".")
}

function New-Card([string]$plainHeading, [string]$anchor) {
    $title = $plainHeading
    $meta = ""
    $citation = [regex]::Match($plainHeading, '^(?<authors>.+?)\s*\((?<year>\d{4})[^)]*\)\.?\s*(?<rest>.*)$')
    if ($citation.Success) {
        $year = $citation.Groups["year"].Value
        $rest = $citation.Groups["rest"].Value
        $titleEnd = [regex]::Match($rest, '(?<=[.?!])\s|\s(?=\[)')
        if ($titleEnd.Success) {
            $title = $rest.Substring(0, $titleEnd.Index)
            $venue = Format-Venue $rest.Substring($titleEnd.Index + 1) $year
        }
        else {
            $title = $rest
            $venue = ""
        }
        $title = $title.Trim().TrimEnd(".")
        $meta = (Format-Authors $citation.Groups["authors"].Value) + " (" + $year + ")"
        if ($venue) {
            # Middle dot, written as a code so Windows PowerShell 5.1 reads this file correctly without a BOM.
            $meta += " " + [char]0x00B7 + " " + $venue
        }
    }

    $linkText = $title -replace '([\[\]])', '\$1'
    $lines = @("- [" + $linkText + "](" + $SummaryUrl + "#" + $anchor + ")")
    if ($meta) {
        $lines += "  " + $meta
    }
    return , $lines
}

# Themes and studies in summary order, with the same de-duplicated anchors the summary page uses.
function Read-Summary([string]$path) {
    $themes = New-Object System.Collections.ArrayList
    $usedAnchors = @{}
    $theme = $null
    foreach ($line in (Read-TextLines $path)) {
        $heading = [regex]::Match($line, '^(?<level>#{2,3})\s+(?<text>.+?)\s*$')
        if (-not $heading.Success) {
            continue
        }
        $plain = ConvertTo-PlainText $heading.Groups["text"].Value
        if ($heading.Groups["level"].Value -eq "##") {
            $theme = [pscustomobject]@{ Name = $plain; Studies = (New-Object System.Collections.ArrayList) }
            [void]$themes.Add($theme)
        }
        else {
            $baseAnchor = Get-StudyAnchor $plain
            $anchor = $baseAnchor
            for ($suffix = 2; $usedAnchors.ContainsKey($anchor); $suffix++) {
                $anchor = $baseAnchor + "-" + $suffix
            }
            $usedAnchors[$anchor] = $true
            if ($theme) {
                [void]$theme.Studies.Add([pscustomobject]@{ Heading = $plain; Anchor = $anchor })
            }
        }
    }
    return , $themes
}

# Splits index.md into front matter, the text before the first theme, and theme sections with their cards.
function Read-Index([string]$path) {
    $lines = Read-TextLines $path
    $index = [pscustomobject]@{
        FrontMatter = (New-Object System.Collections.ArrayList)
        Intro = (New-Object System.Collections.ArrayList)
        Sections = (New-Object System.Collections.ArrayList)
    }

    $position = 0
    if ($lines.Count -gt 0 -and $lines[0] -eq "---") {
        [void]$index.FrontMatter.Add($lines[0])
        for ($position = 1; $position -lt $lines.Count; $position++) {
            [void]$index.FrontMatter.Add($lines[$position])
            if ($lines[$position] -eq "---") {
                $position++
                break
            }
        }
    }

    $section = $null
    $card = $null
    for (; $position -lt $lines.Count; $position++) {
        $line = $lines[$position]
        $themeHeading = [regex]::Match($line, '^##\s+(?<name>.+?)\s*$')
        $cardLink = [regex]::Match($line, '^[-*]\s+\[.*\]\(' + [regex]::Escape($SummaryUrl) + '#(?<anchor>[^)\s]+)\)')

        if ($themeHeading.Success) {
            $section = [pscustomobject]@{
                Name = $themeHeading.Groups["name"].Value
                Description = (New-Object System.Collections.ArrayList)
                Cards = [ordered]@{}
            }
            [void]$index.Sections.Add($section)
            $card = $null
        }
        elseif ($section -and $cardLink.Success) {
            $card = New-Object System.Collections.ArrayList
            [void]$card.Add($line)
            $section.Cards[$cardLink.Groups["anchor"].Value] = $card
        }
        elseif ($card -and $line -match '^\s+\S') {
            [void]$card.Add($line)
        }
        else {
            $card = $null
            if ($section) {
                [void]$section.Description.Add($line)
            }
            else {
                [void]$index.Intro.Add($line)
            }
        }
    }
    return $index
}

function Get-TrimmedBlock($lines) {
    $block = @($lines)
    $first = 0
    $last = $block.Count - 1
    while ($first -le $last -and -not $block[$first].Trim()) {
        $first++
    }
    while ($last -ge $first -and -not $block[$last].Trim()) {
        $last--
    }
    if ($first -gt $last) {
        return , @()
    }
    return , $block[$first..$last]
}

# The index section that already holds most of this theme's studies, else one with the same name.
function Find-Section($theme, $sections, $claimed) {
    $best = $null
    $bestCount = 0
    foreach ($section in $sections) {
        if ($claimed.Contains($section)) {
            continue
        }
        $count = @($theme.Studies | Where-Object { $section.Cards.Contains($_.Anchor) }).Count
        if ($count -gt $bestCount) {
            $best = $section
            $bestCount = $count
        }
    }
    if ($best) {
        return $best
    }
    foreach ($section in $sections) {
        if (-not $claimed.Contains($section) -and (ConvertTo-Slug $section.Name) -eq (ConvertTo-Slug $theme.Name)) {
            return $section
        }
    }
    return $null
}

$themes = Read-Summary $SummaryPath
$index = Read-Index $IndexPath

$existingCards = @{}
foreach ($section in $index.Sections) {
    foreach ($anchor in $section.Cards.Keys) {
        $existingCards[$anchor] = $section.Cards[$anchor]
    }
}

$output = New-Object System.Collections.ArrayList
if ($index.FrontMatter.Count -gt 0) {
    $output.AddRange(@($index.FrontMatter))
    [void]$output.Add("")
}
$intro = Get-TrimmedBlock $index.Intro
if ($intro.Count -gt 0) {
    $output.AddRange($intro)
    [void]$output.Add("")
}

$claimed = New-Object System.Collections.ArrayList
$added = 0
foreach ($theme in $themes) {
    if ($theme.Studies.Count -eq 0) {
        continue
    }
    $section = Find-Section $theme $index.Sections $claimed
    $name = $theme.Name
    $description = @()
    if ($section) {
        [void]$claimed.Add($section)
        $name = $section.Name
        $description = Get-TrimmedBlock $section.Description
    }

    [void]$output.Add("## " + $name)
    [void]$output.Add("")
    if ($description.Count -gt 0) {
        $output.AddRange($description)
        [void]$output.Add("")
    }
    foreach ($study in $theme.Studies) {
        if ($existingCards.ContainsKey($study.Anchor)) {
            $output.AddRange(@($existingCards[$study.Anchor]))
        }
        else {
            $output.AddRange((New-Card $study.Heading $study.Anchor))
            $added++
        }
    }
    [void]$output.Add("")
}

$original = [System.IO.File]::ReadAllText($IndexPath)
$newline = "`n"
if ($original.Contains("`r`n")) {
    $newline = "`r`n"
}
$updated = (($output -join "`n").TrimEnd() + "`n") -replace "`n", $newline

if ($updated -ne $original) {
    [System.IO.File]::WriteAllText($IndexPath, $updated, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "index.md updated ($added new card(s))."
}
