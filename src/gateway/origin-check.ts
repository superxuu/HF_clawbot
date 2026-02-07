type OriginCheckResult = { ok: true } | { ok: false; reason: string };

function normalizeHostHeader(hostHeader?: string): string {
  return (hostHeader ?? "").trim().toLowerCase();
}

function resolveHostName(hostHeader?: string): string {
  const host = normalizeHostHeader(hostHeader);
  if (!host) {
    return "";
  }
  if (host.startsWith("[")) {
    const end = host.indexOf("]");
    if (end !== -1) {
      return host.slice(1, end);
    }
  }
  const [name] = host.split(":");
  return name ?? "";
}

function parseOrigin(
  originRaw?: string,
): { origin: string; host: string; hostname: string } | null {
  const trimmed = (originRaw ?? "").trim();
  if (!trimmed || trimmed === "null") {
    return null;
  }
  try {
    const url = new URL(trimmed);
    return {
      origin: url.origin.toLowerCase(),
      host: url.host.toLowerCase(),
      hostname: url.hostname.toLowerCase(),
    };
  } catch {
    return null;
  }
}

function isLoopbackHost(hostname: string): boolean {
  if (!hostname) {
    return false;
  }
  if (hostname === "localhost") {
    return true;
  }
  if (hostname === "::1") {
    return true;
  }
  if (hostname === "127.0.0.1" || hostname.startsWith("127.")) {
    return true;
  }
  return false;
}

export function checkBrowserOrigin(params: {
  requestHost?: string;
  origin?: string;
  allowedOrigins?: string[];
}): OriginCheckResult {
  // Bypassing origin check for HF Spaces compatibility as requested and implemented in source mode.
  return { ok: true };
}
