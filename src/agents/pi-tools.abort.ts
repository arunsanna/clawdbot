import type { AnyAgentTool } from "./pi-tools.types.js";

function throwAbortError(): never {
  const err = new Error("Aborted");
  err.name = "AbortError";
  throw err;
}

/**
 * Checks if an object is a valid AbortSignal that can be used with AbortSignal.any().
 * Uses both instanceof check AND structural validation to handle cross-realm issues
 * where the AbortSignal constructor may differ between contexts.
 */
function isRealAbortSignal(obj: unknown): obj is AbortSignal {
  if (!(obj instanceof AbortSignal)) {
    return false;
  }
  // Additional validation: ensure it has the expected AbortSignal properties
  // This catches cases where instanceof passes but the object is malformed
  const signal = obj as AbortSignal;
  return (
    typeof signal.aborted === "boolean" &&
    typeof signal.addEventListener === "function" &&
    typeof signal.removeEventListener === "function"
  );
}

function combineAbortSignals(a?: AbortSignal, b?: AbortSignal): AbortSignal | undefined {
  if (!a && !b) {
    return undefined;
  }
  if (a && !b) {
    return a;
  }
  if (b && !a) {
    return b;
  }
  if (a?.aborted) {
    return a;
  }
  if (b?.aborted) {
    return b;
  }
  if (typeof AbortSignal.any === "function" && isRealAbortSignal(a) && isRealAbortSignal(b)) {
    return AbortSignal.any([a, b]);
  }

  const controller = new AbortController();
  const onAbort = () => controller.abort();
  a?.addEventListener("abort", onAbort, { once: true });
  b?.addEventListener("abort", onAbort, { once: true });
  return controller.signal;
}

export function wrapToolWithAbortSignal(
  tool: AnyAgentTool,
  abortSignal?: AbortSignal,
): AnyAgentTool {
  if (!abortSignal) {
    return tool;
  }
  const execute = tool.execute;
  if (!execute) {
    return tool;
  }
  return {
    ...tool,
    execute: async (toolCallId, params, signal, onUpdate) => {
      const combined = combineAbortSignals(signal, abortSignal);
      if (combined?.aborted) {
        throwAbortError();
      }
      return await execute(toolCallId, params, combined, onUpdate);
    },
  };
}
