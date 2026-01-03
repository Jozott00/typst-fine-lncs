#import "../../src/lib.typ": author, corollary, definition, example, institute, lemma, lncs, proof, proposition, theorem

#show: lncs.with(
  title: "Contribution Title",
)

= Section with example
#example[$1+1=2$]
#example(name: "Simple Math")[$1+1=2$]
#theorem[Every planar graph can be 4-coloured.]
#theorem(name: "Cook-Levin")[SAT is NP-complete.]
#definition[$x+0:=x$ and $x+(y+1)=(x+1)+y$]
#definition(name: "Transitivity")[$a circle.small b and b circle.small c ==> a circle.small c$]
#corollary[$1+1=2$]
#corollary(name: "Named")[$1+1=2$]
#proof[An exercise for the reader.]
#proof(name: "Fancy")[Trivial.]
#lemma[My cool lemma.]
#lemma(name: "Named Lemma")[My cool named lemma.]
#proposition[My proposition.]
#proposition(name: "Named Proposition")[My named proposition.]
