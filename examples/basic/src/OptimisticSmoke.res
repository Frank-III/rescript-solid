open Solid

let _signalSmoke = {
  let (count, _setCount) = createSignal(1)
  let (_derived, _setDerived) = createSignalFromFn(() => count() + 1)
  let (_derivedWithInitial, _setDerivedWithInitial) =
    createSignalFromFnWithInitial(() => count() + 2, 0)
  let (_asyncDerived, _setAsyncDerived) =
    createSignalFromAsyncFn(() => Promise.resolve(count() + 3))
  let (_optimistic, _setOptimistic) = createOptimistic(0)
  let (_optimisticFromFn, _setOptimisticFromFn) = createOptimisticFromFn(() => count())
  let (_optimisticFromFnWithInitial, _setOptimisticFromFnWithInitial) =
    createOptimisticFromFnWithInitial(() => count() + 1, 0)
  let _path = storePath(["todos", "0"])
  ()
}

let _storeSmoke = {
  let (_todos, _setTodos) = SolidStore.createOptimisticStore(["a", "b"])
  let (_projected, _setProjected) =
    SolidStore.createOptimisticStoreFromFn(() => ["x", "y"], ~initialValue=["seed"], ())
  let (_fromFn, _setFromFn) =
    SolidStore.createStoreFromFn(() => [1, 2, 3], ~initialValue=[0], ())
  ()
}
