import { z } from "zod";

export const ChannelHeartbeatVisibilitySchema = z
  .object({
    showOk: z.boolean().optional(),
    showAlerts: z.boolean().optional(),
    useIndicator: z.boolean().optional(),
  })
  .strict()
  .optional();

/**
 * Auto-restart config for channels that stop due to recoverable errors.
 * Enabled by default with sensible defaults matching web reconnect behavior.
 */
export const ChannelAutoRestartConfigSchema = z
  .object({
    /** Enable auto-restart (default: true) */
    enabled: z.boolean().optional(),
    /** Max restart attempts before giving up (default: 12) */
    maxAttempts: z.number().int().min(0).max(100).optional(),
    /** Initial delay in ms before first restart (default: 2000) */
    initialDelayMs: z.number().int().min(0).optional(),
    /** Maximum delay cap in ms (default: 30000) */
    maxDelayMs: z.number().int().min(0).optional(),
  })
  .strict()
  .optional();
