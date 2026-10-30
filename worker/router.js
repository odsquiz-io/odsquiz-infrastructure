const apiRoutes = [
  ["/api/auth", "AUTH_ORIGIN"],
  ["/api/initiatives", "INITIATIVES_ORIGIN"],
  ["/api/quiz", "QUIZ_ORIGIN"],
  ["/api/admin", "ADMIN_ORIGIN"],
];

const offlinePage = `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ODS Quiz</title>
<style>
body{margin:0;min-height:100vh;display:grid;place-items:center;font-family:system-ui,sans-serif;background:#f6f7f9;color:#1f2933}
main{max-width:28rem;padding:2rem;text-align:center}
h1{font-size:1.5rem;margin:0 0 .75rem}
p{margin:0;line-height:1.5;color:#52606d}
</style>
</head>
<body>
<main>
<h1>ODS Quiz</h1>
<p>A plataforma está temporariamente fora do ar. Tente novamente mais tarde.</p>
</main>
</body>
</html>`;

function routeFor(pathname) {
  return apiRoutes.find(
    ([prefix]) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

// Cloud Run answers this page when the service does not exist, which happens
// while the billable infrastructure is stopped.
async function isServiceMissing(response) {
  if (response.status !== 404) return false;
  const type = response.headers.get("content-type") ?? "";
  if (!type.startsWith("text/html")) return false;
  const body = await response.clone().text();
  return body.includes("The requested URL was not found on this server.");
}

function offline(isApi) {
  const headers = { "Cache-Control": "no-store", "Retry-After": "3600" };
  if (isApi) {
    return Response.json({ error: "service_unavailable" }, { status: 503, headers });
  }
  return new Response(offlinePage, {
    status: 503,
    headers: { ...headers, "Content-Type": "text/html; charset=utf-8" },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.protocol === "http:") {
      url.protocol = "https:";
      return Response.redirect(url.toString(), 301);
    }

    const route = routeFor(url.pathname);
    const origin = env[route ? route[1] : "FRONTEND_ORIGIN"];
    const upstream = new Request(new URL(url.pathname + url.search, origin), request);
    upstream.headers.set("X-Forwarded-Host", url.host);
    upstream.headers.set("X-Forwarded-Proto", "https");

    const response = await fetch(upstream, { redirect: "manual" });
    if (await isServiceMissing(response)) return offline(Boolean(route));
    return response;
  },
};
