// Pi exposes no hooks for these transcript behaviours, so the UI extension wraps Pi's own methods.
// Each wrapper keeps the original on a symbol so /reload re-wraps the original instead of stacking
// wrappers. A missing method is skipped, so a Pi update falls back to Pi's own behaviour.

const ORIGINAL = Symbol.for("james.ui.original");
const ESCAPES = /\x1b\[[0-9;]*m|\x1b\][^\x07]*\x07|\x1b\][^\x1b]*\x1b\\/g;

type Method = (this: never, ...args: never[]) => unknown;
type Patched<T extends Method> = T & { [ORIGINAL]?: T };

export const plain = (line: string) => line.replace(ESCAPES, "");

export function patchMethod<T extends Method>(target: object, name: string, wrap: (original: T) => T): void {
  const current: Patched<T> | undefined = Reflect.get(target, name);
  if (typeof current !== "function") return;
  const original = current[ORIGINAL] ?? current;
  const wrapped: Patched<T> = wrap(original);
  wrapped[ORIGINAL] = original;
  Reflect.set(target, name, wrapped);
}
