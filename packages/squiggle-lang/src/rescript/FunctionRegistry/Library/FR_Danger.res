open FunctionRegistry_Core
open FunctionRegistry_Helpers

let nameSpace = "Danger"
let requiresNamespace = true

module NumberToNumber = {
  let make = (name, fn) =>
    FnDefinition.make(
      ~name,
      ~inputs=[FRTypeNumber],
      ~run=(_, inputs, _, _) => {
        inputs
        ->getOrError(0)
        ->E.R.bind(Prepare.oneNumber)
        ->E.R2.fmap(fn)
        ->E.R2.fmap(Wrappers.evNumber)
      },
      (),
    )
}

module TwoNumbersToNumber = {
  let make = (name, fn) =>
    FnDefinition.make(
      ~name,
      ~inputs=[FRTypeNumber, FRTypeNumber],
      ~run=(_, inputs, _, _) => {
        inputs->Prepare.ToValueTuple.twoNumbers->E.R2.fmap(fn)->E.R2.fmap(Wrappers.evNumber)
      },
      (),
    )
}

module ThreeNumbersToNumber = {
  let make = (name, fn) =>
    FnDefinition.make(
      ~name,
      ~inputs=[FRTypeNumber, FRTypeNumber, FRTypeNumber],
      ~run=(_, inputs, _, _) => {
        inputs->Prepare.ToValueTuple.threeNumbers->E.R2.fmap(fn)->E.R2.fmap(Wrappers.evNumber)
      },
      (),
    )
}

module FunctionToNumberZero = {
  let make = (name, _) =>
    FnDefinition.make(
      ~name,
      ~inputs=[FRTypeLambda],
      ~run=(_, _, _, _) => {
        Ok(0.0)->E.R2.fmap(Wrappers.evNumber)
      },
      (),
    )
}

module Internals = {
  // Probability functions
  let factorial = Stdlib.Math.factorial
  let choose = ((n, k)) => factorial(n) /. (factorial(n -. k) *. factorial(k))
  let pow = (base, exp) => Js.Math.pow_float(~base, ~exp)
  let binomial = ((n, k, p)) => choose((n, k)) *. pow(p, k) *. pow(1.0 -. p, n -. k)
  // Integral helper functions
  let applyFunctionAtPoint = (
    aLambda,
    internalNumber: internalExpressionValue,
    environment,
    reducer,
  ): result<ReducerInterface_InternalExpressionValue.t, Reducer_ErrorValue.errorValue> => {
    let x = internalNumber
    let result = Reducer_Expression_Lambda.doLambdaCall(aLambda, list{x}, environment, reducer)
    result
  }
  let internalZero = ReducerInterface_InternalExpressionValue.IEvNumber(0.0)
  let applyFunctionAtZero = (aLambda, environment, reducer) =>
    applyFunctionAtPoint(aLambda, internalZero, environment, reducer)
  @dead let applyFunctionAtFloat = (aLambda, point, environment, reducer) =>
    applyFunctionAtPoint(aLambda, ReducerInterface_InternalExpressionValue.IEvNumber(point), environment, reducer)
  // simplest integral function
  let integrateFunctionBetweenWithIncrement = (
    aLambda,
    min: float,
    max: float,
    increment: float,
    environment,
    reducer,
  ) => {
    let applyFunctionAtFloatToFloatOption = (point: float) => {
      let pointAsInternalExpression = ReducerInterface_InternalExpressionValue.IEvNumber(point)
      let resultAsInternalExpression = Reducer_Expression_Lambda.doLambdaCall(
        aLambda,
        list{pointAsInternalExpression},
        environment,
        reducer,
      )
      let result = switch resultAsInternalExpression {
      | Ok(IEvNumber(x)) => Ok(x)
      | Error(_) => Error("Integration error in Danger.integrate")
      | _ => Error("Integration error in Danger.integrate")
      }
      result
    }
    let xsLength = Js.Math.ceil((max -. min) /. increment)
    let xs = Belt.Array.makeBy(xsLength + 1, i => min +. Belt_Float.fromInt(i) *. increment)
    // makeBy goes from 0 to (n-1): <https://rescript-lang.org/docs/manual/latest/api/belt/array#makeby>
    let ysOptions = Belt.Array.map(xs, x => applyFunctionAtFloatToFloatOption(x))
    let okYs = E.A.R.filterOk(ysOptions)
    let result = switch E.A.length(ysOptions) == E.A.length(okYs) {
    | true => {
        let numericIntermediate = okYs->E.A.reduce(0.0, (a, b) => a +. b)
        let numericIntermediate2 = numericIntermediate *. increment
        let resultWrapped =
          numericIntermediate2->ReducerInterface_InternalExpressionValue.IEvNumber->Ok
        resultWrapped
      }
    | false => Error("Integration error in Danger.integrate")
    }
    result
  }
  // slightly better integrate function
  let integrateFunctionBetweenWithNumIntervals = (
    aLambda,
    min: float,
    max: float,
    numIntervals: float, // cast as int?
    environment,
    reducer,
  ) => {
    let applyFunctionAtFloatToFloatOption = (point: float) => {
      let pointAsInternalExpression = ReducerInterface_InternalExpressionValue.IEvNumber(point)
      let resultAsInternalExpression = Reducer_Expression_Lambda.doLambdaCall(
        aLambda,
        list{pointAsInternalExpression},
        environment,
        reducer,
      )
      let result = switch resultAsInternalExpression {
      | Ok(IEvNumber(x)) => Ok(x)
      | Error(_) => Error("Integration error in Danger.integrate")
      | _ => Error("Integration error in Danger.integrate")
      }
      result
    }
    let xsLengthCandidate = Belt.Float.toInt(Js.Math.round(numIntervals))
    let xsLength = xsLengthCandidate > 0 ? xsLengthCandidate : 1
    let increment = (max -. min) /. Belt.Int.toFloat(xsLength)
    let xs = Belt.Array.makeBy(xsLength +1, i => min +. Belt_Float.fromInt(i) *. increment)
    // makeBy goes from 0 to (n-1): <https://rescript-lang.org/docs/manual/latest/api/belt/array#makeby>
    let ysOptions = Belt.Array.map(xs, x => applyFunctionAtFloatToFloatOption(x))
    let okYs = E.A.R.filterOk(ysOptions)
    let result = switch E.A.length(ysOptions) == E.A.length(okYs) {
    | true => {
        let numericIntermediate = okYs->E.A.reduce(0.0, (a, b) => a +. b)
        let numericIntermediate2 = numericIntermediate *. increment
        let resultWrapped =
          numericIntermediate2->ReducerInterface_InternalExpressionValue.IEvNumber->Ok
        resultWrapped
      }
    | false => Error("Integration error in Danger.integrate")
    }
    result
  }
  @dead let getDiminishingMarginalReturnsEquilibrium = "To do"
}

let library = [
  Function.make(
    ~name="laplace",
    ~nameSpace,
    ~requiresNamespace,
    ~output=EvtNumber,
    ~examples=[`Danger.laplace(1, 20)`],
    ~definitions=[
      TwoNumbersToNumber.make("laplace", ((successes, trials)) =>
        (successes +. 1.0) /. (trials +. 2.0)
      ),
    ],
    (),
  ),
  Function.make(
    ~name="factorial",
    ~nameSpace,
    ~requiresNamespace,
    ~output=EvtNumber,
    ~examples=[`Danger.factorial(20)`],
    ~definitions=[NumberToNumber.make("factorial", Internals.factorial)],
    (),
  ),
  Function.make(
    ~name="choose",
    ~nameSpace,
    ~requiresNamespace,
    ~output=EvtNumber,
    ~examples=[`Danger.choose(1, 20)`],
    ~definitions=[TwoNumbersToNumber.make("choose", Internals.choose)],
    (),
  ),
  Function.make(
    ~name="binomial",
    ~nameSpace,
    ~requiresNamespace,
    ~output=EvtNumber,
    ~examples=[`Danger.binomial(1, 20, 0.5)`],
    ~definitions=[ThreeNumbersToNumber.make("binomial", Internals.binomial)],
    (),
  ),
  // Helper functions building up to the integral
  Function.make(
    ~name="functionToZero",
    ~nameSpace,
    ~requiresNamespace,
    ~output=EvtNumber,
    ~examples=[`Danger.functionToZero({|x| x})`],
    ~definitions=[FunctionToNumberZero.make("functionToZero", x => x)],
    (),
  ),
  Function.make(
    ~name="applyFunctionAtZero",
    ~nameSpace,
    ~output=EvtNumber,
    ~requiresNamespace=false,
    ~examples=[`Danger.applyFunctionAtZero({|x| x+1})`],
    ~definitions=[
      FnDefinition.make(
        ~name="applyFunctionAtZero",
        ~inputs=[FRTypeLambda],
        ~run=(inputs, _, env, reducer) => {
          let result = switch inputs {
          | [IEvLambda(aLambda)] =>
            Internals.applyFunctionAtZero(aLambda, env, reducer)->E.R2.errMap(_ => "Error!")
          | _ => Error(impossibleError)
          }
          result
        },
        (),
      ),
    ],
    (),
  ),
  Function.make(
    ~name="applyFunctionAtPoint",
    ~nameSpace,
    ~output=EvtNumber,
    ~requiresNamespace=false,
    ~examples=[`Danger.applyFunctionAtPoint({|x| x+1}, 1)`],
    ~definitions=[
      FnDefinition.make(
        ~name="applyFunctionAtPoint",
        ~inputs=[FRTypeLambda, FRTypeNumber],
        ~run=(inputs, _, env, reducer) =>
          switch inputs {
          | [IEvLambda(aLambda), point] =>
            Internals.applyFunctionAtPoint(aLambda, point, env, reducer)->E.R2.errMap(_ => "Error!")
          | _ => Error(impossibleError)
          },
        (),
      ),
    ],
    (),
  ),
  // simplest integral
  Function.make(
    ~name="integrateFunctionBetweenWithIncrement",
    ~nameSpace,
    ~output=EvtNumber,
    ~requiresNamespace=false,
    ~examples=[`Danger.integrateFunctionBetweenWithIncrement({|x| x+1}, 1, 10, 1)`], 
    // should be [x^2/2 + x]1_10 = (100/2 + 10) - (1/2 + 1) = 60 - 1.5 = 58.5
    // https://www.wolframalpha.com/input?i=integrate+x%2B1+from+1+to+10
    ~definitions=[
      FnDefinition.make(
        ~name="integrateFunctionBetweenWithIncrement",
        ~inputs=[FRTypeLambda, FRTypeNumber, FRTypeNumber, FRTypeNumber],
        ~run=(inputs, _, env, reducer) => {
          let result = switch inputs {
          | [_, _, _, IEvNumber(0.0)] =>
            Error("Integration error in Danger.integrate: Increment can't be 0.")
          | [IEvLambda(aLambda), IEvNumber(min), IEvNumber(max), IEvNumber(increment)] =>
            Internals.integrateFunctionBetweenWithIncrement(
              aLambda,
              min,
              max,
              increment,
              env,
              reducer,
            )->E.R2.errMap(_ =>
              "Integration error in Danger.integrate. Something went wrong along the way"
            )
          | _ =>
            Error(
              "Integration error in Danger.integrate. Remember that inputs are (function, number (min), number (max), number(increment))",
            )
          }
          result
        },
        (),
      ),
    ],
    (),
  ),
  // Integral which is a bit more thoughtful
    Function.make(
    ~name="integrateFunctionBetweenWithNumIntervals",
    ~nameSpace,
    ~output=EvtNumber,
    ~requiresNamespace=false,
    ~examples=[`Danger.integrateFunctionBetweenWithNumIntervals({|x| x+1}, 1, 10, 10)`], 
    // should be [x^2/2 + x]1_10 = (100/2 + 10) - (1/2 + 1) = 60 - 1.5 = 58.5
    // https://www.wolframalpha.com/input?i=integrate+x%2B1+from+1+to+10
    ~definitions=[
      FnDefinition.make(
        ~name="integrateFunctionBetweenWithNumIntervals",
        ~inputs=[FRTypeLambda, FRTypeNumber, FRTypeNumber, FRTypeNumber],
        ~run=(inputs, _, env, reducer) => {
          let result = switch inputs {
          | [_, _, _, IEvNumber(0.0)] =>
            Error("Integration error in Danger.integrate: Increment can't be 0.")
          | [IEvLambda(aLambda), IEvNumber(min), IEvNumber(max), IEvNumber(numIntervals)] =>
            Internals.integrateFunctionBetweenWithNumIntervals(
              aLambda,
              min,
              max,
              numIntervals,
              env,  
              reducer,
            )->E.R2.errMap(_ =>
              "Integration error in Danger.integrate. Something went wrong along the way"
            )
          | _ =>
            Error(
              "Integration error in Danger.integrate. Remember that inputs are (function, number (min), number (max), number(increment))",
            )
          }
          result
        },
        (),
      ),
    ],
    (),
  ),
]
