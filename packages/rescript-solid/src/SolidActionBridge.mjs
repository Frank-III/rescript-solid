import * as Solid from "solid-js";

export function done(value) {
  return { tag: "done", value };
}

export function awaitPromise(promise, cont) {
  return { tag: "await", promise, cont };
}

function isDone(step) {
  return step !== null && typeof step === "object" && step.tag === "done";
}

function isAwait(step) {
  return (
    step !== null &&
    typeof step === "object" &&
    step.tag === "await" &&
    typeof step.cont === "function"
  );
}

// Bridge ReScript's step-machine API to Solid 2.0-style action(generator).
export function actionFromStepper(stepper) {
  const generatorFn = function* (...args) {
    let step = stepper(...args);

    while (true) {
      if (isDone(step)) {
        return step.value;
      }

      if (!isAwait(step)) {
        throw new Error(
          "Invalid action step. Use Solid.doneStep(...) and Solid.awaitStep(...)."
        );
      }

      const value = yield step.promise;
      step = step.cont(value);
    }
  };

  if (typeof Solid.action === "function") {
    return Solid.action(generatorFn);
  }

  // Solid 1.x compatibility: drive the generator without transition semantics.
  return (...args) => {
    const iterator = generatorFn(...args);

    return new Promise((resolve, reject) => {
      const run = (method, value) => {
        let result;

        try {
          result = iterator[method](value);
        } catch (error) {
          reject(error);
          return;
        }

        if (result.done) {
          resolve(result.value);
          return;
        }

        Promise.resolve(result.value).then(
          nextValue => run("next", nextValue),
          error => run("throw", error)
        );
      };

      run("next");
    });
  };
}
