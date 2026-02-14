---
name: trafilatura-expert
description: "Extract clean text and metadata from web pages using the Trafilatura CLI. Use for web scraping, article extraction, URL-to-text conversion, batch processing, sitemap/feed discovery. Assumes trafilatura is installed and in PATH."
---

# Trafilatura Expert

Extract clean article text from web pages. Fast, accurate, no bullshit.

## Quick Start

```bash
# Single URL to stdout
trafilatura -u "https://example.com/article"

# Save to file
trafilatura -u "https://example.com/article" > article.txt

# Markdown output
trafilatura -u "https://example.com/article" --markdown

# JSON with metadata
trafilatura -u "https://example.com/article" --json --with-metadata
```

## Common Patterns

| Task | Command |
|------|---------|
| Clean article text | `trafilatura -u URL` |
| With links preserved | `trafilatura -u URL --links` |
| With formatting (bold/italic) | `trafilatura -u URL --formatting` |
| Only specific language | `trafilatura -u URL --target-language en` |
| Fast extraction (no fallback) | `trafilatura -u URL -f` |
| Remove duplicates | `trafilatura -u URL --deduplicate` |
| Exclude comments/tables | `trafilatura -u URL --no-comments --no-tables` |

## Batch Processing

```bash
# Process list of URLs
trafilatura -i urls.txt -o output/

# Parallel processing (4 threads)
trafilatura -i urls.txt --parallel 4 -o output/

# Keep directory structure
trafilatura --input-dir html_files/ --keep-dirs -o extracted/
```

## Discovery & Crawling

```bash
# List all URLs from sitemap
trafilatura --sitemap "https://example.com" --list

# List URLs from RSS/Atom feed
trafilatura --feed "https://example.com" --list

# Crawl site (fixed number of pages)
trafilatura --crawl "https://example.com" --list

# Probe for extractable content
trafilatura --probe "https://example.com" --target-language en

# Use Internet Archive fallback
trafilatura -u "https://example.com" --archived
```

## Output Formats

| Format | Flag | Use case |
|--------|------|----------|
| Plain text | (default) or `--output-format txt` | Clean reading |
| Markdown | `--markdown` | Documentation, notes |
| JSON | `--json` | Structured data, metadata |
| CSV | `--csv` | Spreadsheet import |
| XML | `--xml` | Further processing |
| HTML | `--html` | Preserved structure |
| XML-TEI | `--xmltei` | Academic/digital humanities |

## Full CLI Reference

```
Input:
  -i, --input-file FILE     Batch process URLs from file
  --input-dir DIR           Process all files in directory
  -u, --URL URL             Single URL to download
  --parallel N              Number of threads (default: auto)
  -b, --blacklist FILE      URLs to skip

Output:
  --list                    Show URLs without downloading
  -o, --output-dir DIR      Write results to directory
  --backup-dir DIR          Keep copies of downloaded files
  --keep-dirs               Preserve input directory structure

Navigation:
  --feed [URL]              Discover/process feeds
  --sitemap [URL]           Discover/process sitemaps
  --crawl [URL]             Crawl website
  --explore [URL]           Sitemap + crawl combo
  --probe [URL]             Test if content is extractable
  --archived                Fallback to Internet Archive
  --url-filter PATTERN      Only process matching URLs

Extraction:
  -f, --fast                Skip fallback detection (faster)
  --formatting              Keep bold/italic formatting
  --links                   Include link URLs
  --images                  Include image sources
  --no-comments             Exclude comment sections
  --no-tables               Exclude table elements
  --only-with-metadata      Skip if no title/date/URL
  --with-metadata           Include metadata in output
  --target-language CODE    ISO 639-1 (e.g., en, de, fr)
  --deduplicate             Filter duplicate content
  --config-file FILE        Custom extraction config
  --precision               Favor precision over recall
  --recall                  Favor recall over precision

Format:
  --output-format {csv,json,html,markdown,txt,xml,xmltei}
  --csv, --json, --html, --markdown, --xml, --xmltei
```

## Examples

```bash
# Article to markdown with metadata
trafilatura -u "https://blog.example.com/post" --markdown --with-metadata

# Extract German content only
trafilatura -u "https://example.de" --target-language de

# Batch to CSV with metadata
trafilatura -i articles.txt --csv --with-metadata -o extracts/

# Crawl and deduplicate
trafilatura --crawl "https://example.com" --deduplicate -o crawled/

# Filter specific URLs
trafilatura --sitemap "https://example.com" --url-filter "/blog/" --list
```
