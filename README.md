# fine-lncs

**fine-lncs** is a [Typst](https://typst.app) template that tries to closely replicate the look and structure of the official [Springer LNCS (Lecture Notes in Computer Science)](https://www.overleaf.com/latex/templates/springer-lecture-notes-in-computer-science/kzwwpvhwnvfj#.WuA4JS5uZpi) LaTeX template.

## Usage

```typst
#import "@preview/fine-lncs:0.4.0": lncs, institute, author, theorem, proof

#let inst_princ = institute("Princeton University", 
  addr: "Princeton NJ 08544, USA"
)
#let inst_springer = institute("Springer Heidelberg", 
  addr: "Tiergartenstr. 17, 69121 Heidelberg, Germany", 
  email: "lncs@springer.com",
  url: "http://www.springer.com/gp/computer-science/lncs"
)
#let inst_abc = institute("ABC Institute", 
  addr: "Rupert-Karls-University Heidelberg, Heidelberg, Germany", 
  email: "{abc,lncs}@uni-heidelberg.de"
)

#show: lncs.with(
  title: "Contribution Title",
  // Opt.: Set this, if the title is too long to avoid linebreaks in the header of odd pages
  // running-title: "Short version of contribution title"
  thanks: "Supported by organization x.",
  authors: (
    author("First Author", 
      insts: (inst_princ),
      oicd: "0000-1111-2222-3333",
    ),
    author("Second Author", 
      insts: (inst_springer, inst_abc),
      oicd: "1111-2222-3333-4444",
    ),
    author("Third Author", 
      insts: (inst_abc),
      oicd: "2222-3333-4444-5555",
    ),
  ),
  abstract: [
    The abstract should briefly summarize the contents of the paper in
    15--250 words.
  ],
  keywords: ("First keyword", "Second keyword", "Another keyword"),
  bibliography: bibliography("refs.bib")
)

= First Section

My awesome paper ...
```

### Local Usage

If you want to use this template locally, clone it and install it with:

```bash
just install
```

This allows you to import the template using

```typst
#import "@local/fine-lncs:0.4.0": lncs, institute, author, theorem, proof
```

## Development

Common tasks are wrapped in a [`justfile`](https://github.com/casey/just). Run `just` in the repo root to see all recipes:

```text
dev       # Symlink this template into the local @preview package dir (typship dev)
install   # Install this template locally as @local/fine-lncs (typship install local)
fmt       # Format all .typ files in place
fmt-check # Check formatting without modifying files (same as CI)
test      # Run the test suite
ci        # Run everything CI runs
```

Required tools:

- [`just`](https://github.com/casey/just) — command runner
- [`typship`](https://github.com/sjfhsjfh/typship) — local install & dev symlink
- [`typstyle`](https://github.com/typstyle-rs/typstyle) — formatter (`cargo install typstyle`)
- [`tytanic`](https://github.com/tingerrr/tytanic) — test runner (`cargo install tytanic`)

Use `just dev` to symlink this library into your local Typst package directory while you're iterating on it.

### Formatting

All `.typ` files are formatted with `typstyle`. CI enforces this via `just fmt-check`, so before pushing run:

```bash
just fmt
```

### Testing

The project uses [tytanic](https://github.com/tingerrr/tytanic) for tests. Run the full suite with:

```bash
just test
```

### Continuous Integration

Every push to `main` and every pull request runs both the format check and the test suite via GitHub Actions (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)). To reproduce the CI run locally:

```bash
just ci
```
