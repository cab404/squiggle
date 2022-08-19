open ForTS__Types
// If a module is built for TypeScript then it can only refer to ForTS__Types for other types and modules
// The exception is its implementation and private modules
module T = ReducerProject_T
module Private = ReducerProject.Private

/*
  PUBLIC FUNCTIONS
*/

/*
Creates a new project to hold the sources, executables, bindings, and other data. 
The new project runs the sources according to their topological sorting because of the includes and continues.

Any source can include or continue other sources. "Therefore, the project is a graph data structure."
The difference between including and continuing is that includes are stated inside the source code while continues are stated in the project.

To run a group of source codes and get results/bindings, the necessary methods are
- setSource
- setContinues
- parseIncludes
- run or runAll
- getExternalBindings
- getExternalResult

A project has a public field tag with a constant value "reducerProject"
project = {tag: "reducerProject"}
*/
let createProject = (): reducerProject => Private.createProject()->T.Private.castFromInternalProject

/*
Answer all the source ids of all the sources in the project.
*/
let getSourceIds = (project: reducerProject): array<string> =>
  project->T.Private.castToInternalProject->Private.getSourceIds

/*
Sets the source for a given source Id.
*/
let setSource = (project: reducerProject, sourceId: string, value: string): unit =>
  project->T.Private.castToInternalProject->Private.setSource(sourceId, value)

/*
Gets the source for a given source id.
*/
let getSource = (project: reducerProject, sourceId: string): option<string> =>
  project->T.Private.castToInternalProject->Private.getSource(sourceId)

/*
Touches the source for a given source id. This and dependent, sources are set to be re-evaluated.
*/
let touchSource = (project: reducerProject, sourceId: string): unit =>
  project->T.Private.castToInternalProject->Private.touchSource(sourceId)

/*
Cleans the compilation artifacts for a given source ID. The results stay untouched, so compilation won't be run again.

Normally, you would never need the compilation artifacts again as the results with the same sources would never change. However, they are needed in case of any debugging reruns
*/
let clean = (project: reducerProject, sourceId: string): unit =>
  project->T.Private.castToInternalProject->Private.clean(sourceId)

/*
Cleans all the compilation artifacts in all of the project
*/
let cleanAll = (project: reducerProject): unit =>
  project->T.Private.castToInternalProject->Private.cleanAll

/*
Cleans results. Compilation stays untouched to be able to re-run the source.
You would not do this if you were not trying to debug the source code.
*/
let cleanResults = (project: reducerProject, sourceId: string): unit =>
  project->T.Private.castToInternalProject->Private.cleanResults(sourceId)

/*
Cleans all results. Compilations remains untouched to rerun the source.
*/
let cleanAllResults = (project: reducerProject): unit =>
  project->T.Private.castToInternalProject->Private.cleanAllResults

/*
To set the includes one first has to call "parseIncludes". The parsed includes or the parser error is returned.
*/
let getIncludes = (project: reducerProject, sourceId: string): result<
  array<string>,
  Reducer_ErrorValue.errorValue,
> => project->T.Private.castToInternalProject->Private.getIncludes(sourceId)

/*
Answers the source codes after which this source code is continuing
*/
let getContinues = (project: reducerProject, sourceId: string): array<string> =>
  project->T.Private.castToInternalProject->Private.getContinues(sourceId)

/*
 "continues" acts like hidden includes in the source. 
 It is used to define a continuation that is not visible in the source code. 
 You can chain source codes on the web interface for example
*/
let setContinues = (project: reducerProject, sourceId: string, continues: array<string>): unit =>
  project->T.Private.castToInternalProject->Private.setContinues(sourceId, continues)

/*
This source depends on the array of sources returned.
*/
let getDependencies = (project: reducerProject, sourceId: string): array<string> =>
  project->T.Private.castToInternalProject->Private.getDependencies(sourceId)

/*
The sources returned are dependent on this
*/
let getDependents = (project: reducerProject, sourceId: string): array<string> =>
  project->T.Private.castToInternalProject->Private.getDependents(sourceId)

/*
Get the run order for the sources in the project.
*/
let getRunOrder = (project: reducerProject): array<string> =>
  project->T.Private.castToInternalProject->Private.getRunOrder

/*
Get the run order to get the results of this specific source
*/
let getRunOrderFor = (project: reducerProject, sourceId: string) =>
  project->T.Private.castToInternalProject->Private.getRunOrderFor(sourceId)

/*
Parse includes so that you can load them before running. 
Load includes by calling getIncludes which returns the includes that have been parsed. 
It is your responsibility to load the includes before running.
*/ module Topology = ReducerProject_Topology

let parseIncludes = (project: reducerProject, sourceId: string): unit =>
  project->T.Private.castToInternalProject->Private.parseIncludes(sourceId)

/*
Parse the source code if it is not done already. 
Use getRawParse to get the parse tree. 
You would need this function if you want to see the parse tree without running the source code.
*/
let rawParse = (project: reducerProject, sourceId: string): unit =>
  project->T.Private.castToInternalProject->Private.rawParse(sourceId)

/*
Runs a specific source code if it is not done already. The code is parsed if it is not already done. It runs the dependencies if it is not already done.
*/
let run = (project: reducerProject, sourceId: string): unit =>
  project->T.Private.castToInternalProject->Private.run(sourceId)

/*
Runs all of the sources in a project. Their results and bindings will be available
*/
let runAll = (project: reducerProject): unit =>
  project->T.Private.castToInternalProject->Private.runAll

/*
Get the bindings after running this source file or the project
*/
let getBindings = (project: reducerProject, sourceId: string): squiggleValue_Module =>
  project->T.Private.castToInternalProject->Private.getBindings(sourceId)

/*
Get the result after running this source file or the project
*/
let getResult = (project: reducerProject, sourceId: string): option<
  result_<squiggleValue, reducerErrorValue>,
> => project->T.Private.castToInternalProject->Private.getResult(sourceId)

/*
This is a convenience function to get the result of a single source without creating a project. 
However, without a project, you cannot handle include directives.
The source has to be include free
*/
let evaluate = (sourceCode: string): ('r, 'b) => Private.evaluate(sourceCode)

let setEnvironment = (project: reducerProject, environment: environment): unit =>
  project->T.Private.castToInternalProject->Private.setEnvironment(environment)

/*
Foreign function interface is intentionally demolished.
There is another way to do that: Umur.
Also there is no more conversion from javascript to squiggle values currently.
If the conversion to the new project is too difficult, I can add it later.
*/

// let foreignFunctionInterface = (
//   lambdaValue: squiggleValue_Lambda,
//   argArray: array<squiggleValue>,
//   environment: environment,
// ): result_<squiggleValue, reducerErrorValue> => {
//   let accessors = ReducerProject_ProjectAccessors_T.identityAccessorsWithEnvironment(environment)
//   Reducer_Expression_Lambda.foreignFunctionInterface(
//     lambdaValue,
//     argArray,
//     accessors,
//     Reducer_Expression.reduceExpressionInProject,
//   )
// }