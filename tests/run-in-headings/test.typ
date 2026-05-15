#import "../../src/lib.typ": author, institute, lncs, proof, theorem

#let test_inst = institute("Test")

#show: lncs.with(
  title: "Contribution Title",
)

= First Section
== A Subsection Sample

Please note that the first paragraph of a section or subsection is not indented. The first paragraph that follows a table, figure, equation etc. does not need an indent, either.

Subsequent paragraphs, however, are indented.

=== Sampling Heading (Third Level)
Only two levels of headings should be numbered. Lower level headings remain unnumbered; they are formatted as run-in headings.

$ a^2 + b^2 = c^2 $

=== Third level
#lorem(20)

$ p v = R T $
==== Sample Heading (Fourth Level)
The contribution should contain no more than
four levels of headings.

#figure(
  caption: [A test table],
  placement: auto,
  table(
    columns: 2,
    [1],[2],
    [3],[4]
  )
)

==== Fourth Level
#lorem(20)
