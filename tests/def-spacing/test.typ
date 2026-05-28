#import "../../src/lib.typ": author, institute, lncs, proof, theorem, definition

#let test_inst = institute("Test")

#show: lncs.with(
  title: "Contribution Title",
)

= Introduction

First Paragraph.

This is a new paragraph.

#definition[
    A definition that explains the meaning of a term.
]

#definition[
    A definition that explains the meaning of a term.
]

Another paragraph.

#theorem[
    This is a sample theorem. The run-in heading is set in bold, while the
    following text appears in italics. Definitions, lemmas, propositions, and
    corollaries are styled the same way.
]

Another paragraph.
