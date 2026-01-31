import { resolveChannelDefaultAccountId } from "../../channels/plugins/helpers.js";
import { getChannelPlugin, normalizeChannelId } from "../../channels/plugins/index.js";
import { withProgress } from "../../cli/progress.js";
import { loadConfig } from "../../config/config.js";
import { callGateway } from "../../gateway/call.js";
import type { RuntimeEnv } from "../../runtime.js";
import { theme } from "../../terminal/theme.js";

export type ChannelsRestartOptions = {
  channel: string;
  account?: string;
  json?: boolean;
};

export async function channelsRestartCommand(
  opts: ChannelsRestartOptions,
  runtime: RuntimeEnv,
): Promise<void> {
  const channelId = normalizeChannelId(opts.channel);
  if (!channelId) {
    runtime.error(theme.error(`Unknown channel: ${opts.channel}`));
    runtime.exit(1);
    return;
  }

  const plugin = getChannelPlugin(channelId);
  if (!plugin) {
    runtime.error(theme.error(`Channel plugin not found: ${channelId}`));
    runtime.exit(1);
    return;
  }

  const cfg = loadConfig();
  const accountId =
    opts.account?.trim() ||
    resolveChannelDefaultAccountId({ plugin, cfg }) ||
    plugin.config.listAccountIds(cfg)[0];

  if (!accountId) {
    runtime.error(theme.error(`No account configured for channel: ${channelId}`));
    runtime.exit(1);
    return;
  }

  const result = await withProgress(
    { label: `Restarting ${channelId} (${accountId})` },
    async () => {
      return await callGateway({
        method: "channels.restart",
        params: { channel: channelId, accountId },
        timeoutMs: 30_000,
      });
    },
  );

  if (opts.json) {
    runtime.log(JSON.stringify(result, null, 2));
    return;
  }

  if (result && typeof result === "object" && "restarted" in result) {
    const payload = result as {
      channel: string;
      accountId: string;
      restarted: boolean;
    };
    if (payload.restarted) {
      runtime.log(theme.success(`Restarted ${payload.channel} account ${payload.accountId}`));
    } else {
      runtime.log(theme.muted(`Channel ${payload.channel} restart completed`));
    }
  } else {
    runtime.log(theme.muted("Channel restart completed"));
  }
}
