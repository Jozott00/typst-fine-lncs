#let __llncs_style_paper = (
  margin: (
    left: 47.5mm,
    right: 44mm,
    top: 50mm,
    bottom: 45mm,
  ),
)

#let __llncs_style_us_paper = (
  paper: "us-letter",
  ..__llncs_style_paper,
)

#let __llncs_style_a4_paper = (
  paper: "a4",
  ..__llncs_style_paper,
)

#let __llncs_style_book = (
  paper: "a4",
  margin: (
    inside: 15mm,
    outside: 25mm,
    y: 25mm,
  ),
)

#let __llncs_style_cnf = (
  page_config_paper_a4: __llncs_style_a4_paper,
  page_config_paper_us: __llncs_style_us_paper,
  page_config_book: __llncs_style_book,
)
