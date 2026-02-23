import { RpcTarget } from "capnweb";

class RescriptTarget extends RpcTarget {}

export const makeTarget = impl => {
  const target = new RescriptTarget();
  return new Proxy(target, {
    get(obj, prop, receiver) {
      if (prop in impl) {
        const value = impl[prop];
        if (typeof value === "function") {
          return value.bind(impl);
        }
        return value;
      }
      return Reflect.get(obj, prop, receiver);
    },
  });
};
