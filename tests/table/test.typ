

#import "../../src/lib.typ": author, institute, lncs, proof, theorem

#let test_inst = institute("Test")

#show: lncs.with(
  title: "Contribution Title",
)

= Table Test

Testing if the table has the same proportions as the in the Latex template.

#figure(caption: [Table Captions should be placed above the tables])[
  #table(
    columns: 3,
    align: left + bottom,
    table.hline(),
    [Heading level], [Example], [Font size and style],
    table.hline(),
    [Title (centered)],
    text(14pt, weight: "bold", "Lecture Notes"),
    [14 point, bold],
    [1st-level heading],
    text(12pt, weight: "bold")[1 Introduction],
    [12 point, bold],
    [2nd-level heading],
    text(10pt, weight: "bold")[2.1 Printing Area],
    [10 point, bold],
    [3rd-level heading],
    [#text(10pt, weight: "bold")[Run-in Heading in Bold.] Text follows.],
    [10 point, bold],
    [4th-level heading],
    [#text(10pt, style: "italic")[Lowest Level Heading] Text follows.],
    [10 point, italic],
    table.hline(),
  )
] <heading_styles>

With spacings before and after.
