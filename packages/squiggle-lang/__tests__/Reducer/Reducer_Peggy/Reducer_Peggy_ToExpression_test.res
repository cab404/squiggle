module Bindings = Reducer_Bindings
module InternalExpressionValue = ReducerInterface_InternalExpressionValue

open Jest
open Reducer_Peggy_TestHelpers

describe("Peggy to Expression", () => {
  describe("literals operators parenthesis", () => {
    // Note that there is always an outer block. Otherwise, external bindings are ignored at the first statement
    testToExpression("1", "{(:$_endOfOuterBlock_$ () 1)}", ~v="1", ())
    testToExpression("'hello'", "{(:$_endOfOuterBlock_$ () 'hello')}", ~v="'hello'", ())
    testToExpression("true", "{(:$_endOfOuterBlock_$ () true)}", ~v="true", ())
    testToExpression("1+2", "{(:$_endOfOuterBlock_$ () (:add 1 2))}", ~v="3", ())
    testToExpression("add(1,2)", "{(:$_endOfOuterBlock_$ () (:add 1 2))}", ~v="3", ())
    testToExpression("(1)", "{(:$_endOfOuterBlock_$ () 1)}", ())
    testToExpression("(1+2)", "{(:$_endOfOuterBlock_$ () (:add 1 2))}", ())
  })

  describe("unary", () => {
    testToExpression("-1", "{(:$_endOfOuterBlock_$ () (:unaryMinus 1))}", ~v="-1", ())
    testToExpression("!true", "{(:$_endOfOuterBlock_$ () (:not true))}", ~v="false", ())
    testToExpression("1 + -1", "{(:$_endOfOuterBlock_$ () (:add 1 (:unaryMinus 1)))}", ~v="0", ())
    testToExpression("-a[0]", "{(:$_endOfOuterBlock_$ () (:unaryMinus (:$_atIndex_$ :a 0)))}", ())
  })

  describe("multi-line", () => {
    testToExpression("x=1; 2", "{(:$_let_$ :x {1}); (:$_endOfOuterBlock_$ () 2)}", ~v="2", ())
    testToExpression(
      "x=1; y=2",
      "{(:$_let_$ :x {1}); (:$_let_$ :y {2}); (:$_endOfOuterBlock_$ () ())}",
      (),
    )
  })

  describe("variables", () => {
    testToExpression("x = 1", "{(:$_let_$ :x {1}); (:$_endOfOuterBlock_$ () ())}", ())
    testToExpression("x", "{(:$_endOfOuterBlock_$ () :x)}", ~v="Error(x is not defined)", ()) //TODO: value should return error
    testToExpression("x = 1; x", "{(:$_let_$ :x {1}); (:$_endOfOuterBlock_$ () :x)}", ~v="1", ())
  })

  describe("functions", () => {
    testToExpression(
      "identity(x) = x",
      "{(:$_let_$ :identity (:$$_lambda_$$ [x] {:x})); (:$_endOfOuterBlock_$ () ())}",
      (),
    ) // Function definitions become lambda assignments
    testToExpression("identity(x)", "{(:$_endOfOuterBlock_$ () (:identity :x))}", ()) // Note value returns error properly
    testToExpression(
      "f(x) = x> 2 ? 0 : 1; f(3)",
      "{(:$_let_$ :f (:$$_lambda_$$ [x] {(:$$_ternary_$$ (:larger :x 2) 0 1)})); (:$_endOfOuterBlock_$ () (:f 3))}",
      ~v="0",
      (),
    )
  })

  describe("arrays", () => {
    testToExpression("[]", "{(:$_endOfOuterBlock_$ () (:$_constructArray_$))}", ~v="[]", ())
    testToExpression(
      "[0, 1, 2]",
      "{(:$_endOfOuterBlock_$ () (:$_constructArray_$ 0 1 2))}",
      ~v="[0,1,2]",
      (),
    )
    testToExpression(
      "['hello', 'world']",
      "{(:$_endOfOuterBlock_$ () (:$_constructArray_$ 'hello' 'world'))}",
      ~v="['hello','world']",
      (),
    )
    testToExpression(
      "([0,1,2])[1]",
      "{(:$_endOfOuterBlock_$ () (:$_atIndex_$ (:$_constructArray_$ 0 1 2) 1))}",
      ~v="1",
      (),
    )
  })

  describe("records", () => {
    testToExpression(
      "{a: 1, b: 2}",
      "{(:$_endOfOuterBlock_$ () (:$_constructRecord_$ (('a' 1) ('b' 2))))}",
      ~v="{a: 1,b: 2}",
      (),
    )
    testToExpression(
      "{1+0: 1, 2+0: 2}",
      "{(:$_endOfOuterBlock_$ () (:$_constructRecord_$ (((:add 1 0) 1) ((:add 2 0) 2))))}",
      (),
    ) // key can be any expression
    testToExpression(
      "record.property",
      "{(:$_endOfOuterBlock_$ () (:$_atIndex_$ :record 'property'))}",
      (),
    )
    testToExpression(
      "record={property: 1}; record.property",
      "{(:$_let_$ :record {(:$_constructRecord_$ (('property' 1)))}); (:$_endOfOuterBlock_$ () (:$_atIndex_$ :record 'property'))}",
      ~v="1",
      (),
    )
  })

  describe("comments", () => {
    testToExpression("1 # This is a line comment", "{(:$_endOfOuterBlock_$ () 1)}", ~v="1", ())
    testToExpression("1 // This is a line comment", "{(:$_endOfOuterBlock_$ () 1)}", ~v="1", ())
    testToExpression(
      "1 /* This is a multi line comment */",
      "{(:$_endOfOuterBlock_$ () 1)}",
      ~v="1",
      (),
    )
    testToExpression(
      "/* This is a multi line comment */ 1",
      "{(:$_endOfOuterBlock_$ () 1)}",
      ~v="1",
      (),
    )
  })

  describe("ternary operator", () => {
    testToExpression(
      "true ? 1 : 0",
      "{(:$_endOfOuterBlock_$ () (:$$_ternary_$$ true 1 0))}",
      ~v="1",
      (),
    )
    testToExpression(
      "false ? 1 : 0",
      "{(:$_endOfOuterBlock_$ () (:$$_ternary_$$ false 1 0))}",
      ~v="0",
      (),
    )
    testToExpression(
      "true ? 1 : false ? 2 : 0",
      "{(:$_endOfOuterBlock_$ () (:$$_ternary_$$ true 1 (:$$_ternary_$$ false 2 0)))}",
      ~v="1",
      (),
    ) // nested ternary
    testToExpression(
      "false ? 1 : false ? 2 : 0",
      "{(:$_endOfOuterBlock_$ () (:$$_ternary_$$ false 1 (:$$_ternary_$$ false 2 0)))}",
      ~v="0",
      (),
    ) // nested ternary
    describe("ternary bindings", () => {
      testToExpression(
        // expression binding
        "f(a) = a > 5 ? 1 : 0; f(6)",
        "{(:$_let_$ :f (:$$_lambda_$$ [a] {(:$$_ternary_$$ (:larger :a 5) 1 0)})); (:$_endOfOuterBlock_$ () (:f 6))}",
        ~v="1",
        (),
      )
      testToExpression(
        // when true binding
        "f(a) = a > 5 ? a : 0; f(6)",
        "{(:$_let_$ :f (:$$_lambda_$$ [a] {(:$$_ternary_$$ (:larger :a 5) :a 0)})); (:$_endOfOuterBlock_$ () (:f 6))}",
        ~v="6",
        (),
      )
      testToExpression(
        // when false binding
        "f(a) = a < 5 ? 1 : a; f(6)",
        "{(:$_let_$ :f (:$$_lambda_$$ [a] {(:$$_ternary_$$ (:smaller :a 5) 1 :a)})); (:$_endOfOuterBlock_$ () (:f 6))}",
        ~v="6",
        (),
      )
    })
  })

  describe("if then else", () => {
    testToExpression(
      "if true then 2 else 3",
      "{(:$_endOfOuterBlock_$ () (:$$_ternary_$$ true {2} {3}))}",
      (),
    )
    testToExpression(
      "if true then {2} else {3}",
      "{(:$_endOfOuterBlock_$ () (:$$_ternary_$$ true {2} {3}))}",
      (),
    )
    testToExpression(
      "if false then {2} else if false then {4} else {5}",
      "{(:$_endOfOuterBlock_$ () (:$$_ternary_$$ false {2} (:$$_ternary_$$ false {4} {5})))}",
      (),
    ) //nested if
  })

  describe("pipe", () => {
    testToExpression("1 -> add(2)", "{(:$_endOfOuterBlock_$ () (:add 1 2))}", ~v="3", ())
    testToExpression(
      "-1 -> add(2)",
      "{(:$_endOfOuterBlock_$ () (:add (:unaryMinus 1) 2))}",
      ~v="1",
      (),
    ) // note that unary has higher priority naturally
    testToExpression(
      "1 -> add(2) * 3",
      "{(:$_endOfOuterBlock_$ () (:multiply (:add 1 2) 3))}",
      ~v="9",
      (),
    )
  })

  describe("elixir pipe", () => {
    testToExpression("1 |> add(2)", "{(:$_endOfOuterBlock_$ () (:add 1 2))}", ~v="3", ())
  })

  // see testParse for priorities of to and credibleIntervalToDistribution

  describe("inner block", () => {
    // inner blocks are 0 argument lambdas. They can be used whenever a value is required.
    // Like lambdas they have a local scope.
    testToExpression(
      "y=99; x={y=1; y}",
      "{(:$_let_$ :y {99}); (:$_let_$ :x {(:$_let_$ :y {1}); :y}); (:$_endOfOuterBlock_$ () ())}",
      (),
    )
  })

  describe("lambda", () => {
    testToExpression(
      "{|x| x}",
      "{(:$_endOfOuterBlock_$ () (:$$_lambda_$$ [x] {:x}))}",
      ~v="lambda(x=>internal code)",
      (),
    )
    testToExpression(
      "f={|x| x}",
      "{(:$_let_$ :f {(:$$_lambda_$$ [x] {:x})}); (:$_endOfOuterBlock_$ () ())}",
      (),
    )
    testToExpression(
      "f(x)=x",
      "{(:$_let_$ :f (:$$_lambda_$$ [x] {:x})); (:$_endOfOuterBlock_$ () ())}",
      (),
    ) // Function definitions are lambda assignments
    testToExpression(
      "f(x)=x ? 1 : 0",
      "{(:$_let_$ :f (:$$_lambda_$$ [x] {(:$$_ternary_$$ :x 1 0)})); (:$_endOfOuterBlock_$ () ())}",
      (),
    )
  })

  describe("module", () => {
    // testToExpression("Math.pi", "{:Math.pi}", ~v="3.141592653589793", ())
    // Only.test("stdlibrary", () => {
    //  ReducerInterface_StdLib.internalStdLib
    //  ->IEvBindings
    //  ->InternalExpressionValue.toString
    //  ->expect
    //  ->toBe("")
    // })
    testToExpression("Math.pi", "{(:$_endOfOuterBlock_$ () :Math.pi)}", ~v="3.141592653589793", ())
  })
})
