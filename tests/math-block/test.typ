

#import "../../src/lib.typ": author, institute, lncs, proof, theorem

#let test_inst = institute("Test")

#show: lncs.with(
  title: "Contribution Title",
)

= Math Block Test

Testing if math blocks have the same proportions as the in the Latex template. So here comes a formula:

$ p v = R T $

With spacings before and after.
