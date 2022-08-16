module ProjectItem = ReducerProject_ProjectItem
module T = ReducerProject_T
type t = T.Private.t

let getSourceIds = T.Private.getSourceIds
let getItem = T.Private.getItem

let getImmediateDependencies = (this: t, sourceId: string): ProjectItem.T.includesType =>
  getItem(this, sourceId)->ProjectItem.getImmediateDependencies

type topologicalSortState = (Belt.Map.String.t<bool>, list<string>)
let rec topologicalSortUtil = (
  this: t,
  sourceId: string,
  state: topologicalSortState,
): topologicalSortState => {
  let dependencies = getImmediateDependencies(this, sourceId)->Belt.Result.getWithDefault([])
  let (visited, stack) = state
  let myVisited = Belt.Map.String.set(visited, sourceId, true)
  let (newVisited, newStack) = dependencies->Belt.Array.reduce((myVisited, stack), (
    (currVisited, currStack),
    dependency,
  ) => {
    if !Belt.Map.String.getWithDefault(currVisited, dependency, false) {
      topologicalSortUtil(this, dependency, (currVisited, currStack))
    } else {
      (currVisited, currStack)
    }
  })
  (newVisited, list{sourceId, ...newStack})
}

let getTopologicalSort = (this: t): array<string> => {
  let (_visited, stack) = getSourceIds(this)->Belt.Array.reduce((Belt.Map.String.empty, list{}), (
    (currVisited, currStack),
    currId,
  ) =>
    if !Belt.Map.String.getWithDefault(currVisited, currId, false) {
      topologicalSortUtil(this, currId, (currVisited, currStack))
    } else {
      (currVisited, currStack)
    }
  )
  Belt.List.reverse(stack)->Belt.List.toArray
}

let getTopologicalSortFor = (this: t, sourceId) => {
  let runOrder = getTopologicalSort(this)
  let index = runOrder->Js.Array2.indexOf(sourceId)
  let after = Belt.Array.sliceToEnd(runOrder, index + 1)
  let before = Js.Array2.slice(runOrder, ~start=0, ~end_=index + 1)
  (before, after)
}

let getRunOrder = getTopologicalSort

let getRunOrderFor = (this: t, sourceId: string) => {
  let (runOrder, _) = getTopologicalSortFor(this, sourceId)
  runOrder
}

let getDependencies = (this: t, sourceId: string): array<string> => {
  let runOrder = getRunOrderFor(this, sourceId)

  let _ = Js.Array2.pop(runOrder)
  runOrder
}

let getDependents = (this: t, sourceId: string): array<string> => {
  let (_, dependents) = getTopologicalSortFor(this, sourceId)
  dependents
}