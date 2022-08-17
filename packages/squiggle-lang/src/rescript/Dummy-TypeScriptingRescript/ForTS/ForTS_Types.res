/*
  Group all opaque types together for TS. 
  All other modules for TS should use this module
*/
@genType.opaque type internalValue = MyInterface_InternalValue_T.t
@genType.opaque type recordLike = MyInterface_InternalValue_RecordLike.t
@genType.opaque type internalVoid = int
@genType.opaque type errorValue = My_ErrorValue.t
@genType.opaque type result_internalValue = result<internalValue, errorValue> // There has to be a type for each result permutation
@genType.opaque type myProject = {name: string}

//There is no need to map option<> as it becomes nullable