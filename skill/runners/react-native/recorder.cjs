// Record the app's HTTP traffic from React Native's CDP Network domain.
//
//   node recorder.cjs <ws-url> <dir>
//
// Started detached by `framework.sh traffic-arm`; runs on the machine with the
// device, because Metro's inspector socket is on its loopback. Writes into
// <dir>: `pid`, `state` (connecting | connected <time>), and `traffic.ndjson`,
// one finished request per line. Ends on SIGTERM (`traffic-disarm`).
//
// MEASURED (BACKLOG item 87, 6.8) against React Native 0.88 under Expo 58:
// - The proxy wants Origin http://127.0.0.1:<port> and drops a session whose
//   Origin is localhost, so the Origin is built from the URL's own port.
// - Events reach only a connected client, so this has to be attached before
//   the requests it is to see. The agent survives Page.reload; the socket does
//   not survive an app restart, so a closed socket is retried every 2 s, and
//   the target URL is the same once the app reconnects.
// - Expo replaces fetch with expo/fetch, which reports nothing; Metro started
//   with EXPO_PUBLIC_USE_RN_FETCH=1 puts fetch back on React Native's
//   networking, which does.
// - Network.getResponseBody answers after loadingFinished, base64 for JSON.
//
// Node 22 or later: the WebSocket global, which takes an Origin header.
"use strict";
const fs = require("fs");
const path = require("path");

const [url, dir] = process.argv.slice(2);
if (!url || !dir) { console.error("usage: recorder.cjs <ws-url> <dir>"); process.exit(2); }
if (typeof WebSocket !== "function") { console.error("recorder.cjs needs Node 22 or later"); process.exit(1); }
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, "pid"), String(process.pid));
const out = path.join(dir, "traffic.ndjson");
const state = (s) => fs.writeFileSync(path.join(dir, "state"), s + "\n");
const origin = "http://127.0.0.1:" + (new URL(url.replace(/^ws/, "http")).port || "80");

let ws, n = 0;
const pending = new Map();   // requestId -> record being built
const bodyCalls = new Map(); // CDP call id -> requestId

function write(rec) { fs.appendFileSync(out, JSON.stringify(rec) + "\n"); }

function onEvent(method, p) {
  const r = pending.get(p.requestId) || { id: p.requestId };
  pending.set(p.requestId, r);
  switch (method) {
    case "Network.requestWillBeSent":
      r.time = new Date().toISOString();
      r.method = p.request.method; r.url = p.request.url;
      r.requestHeaders = p.request.headers || {};
      if (p.request.postData) r.requestBody = p.request.postData;
      break;
    case "Network.requestWillBeSentExtraInfo":
      r.requestHeaders = Object.assign({}, r.requestHeaders, p.headers);
      break;
    case "Network.responseReceived":
      r.status = p.response.status; r.responseHeaders = p.response.headers || {};
      r.mimeType = p.response.mimeType;
      break;
    case "Network.loadingFinished": {
      const id = ++n;
      bodyCalls.set(id, p.requestId);
      ws.send(JSON.stringify({ id, method: "Network.getResponseBody", params: { requestId: p.requestId } }));
      break;
    }
    case "Network.loadingFailed":
      r.error = p.errorText || "failed";
      write(r); pending.delete(p.requestId);
      break;
  }
}

function connect() {
  state("connecting");
  ws = new WebSocket(url, { headers: { Origin: origin } });
  ws.onopen = () => {
    ws.send(JSON.stringify({ id: ++n, method: "Network.enable" }));
    state("connected " + new Date().toISOString());
  };
  ws.onmessage = (m) => {
    let d; try { d = JSON.parse(String(m.data)); } catch { return; }
    if (d.method && d.method.startsWith("Network.")) return onEvent(d.method, d.params || {});
    const rid = bodyCalls.get(d.id);
    if (rid === undefined) return;
    bodyCalls.delete(d.id);
    const r = pending.get(rid) || { id: rid };
    if (d.result) {
      r.body = d.result.base64Encoded ? Buffer.from(d.result.body || "", "base64").toString("utf8") : d.result.body;
    } else {
      r.bodyError = (d.error && d.error.message) || "no body";
    }
    write(r); pending.delete(rid);
  };
  ws.onclose = () => { state("connecting"); setTimeout(connect, 2000); };
  ws.onerror = () => {};
}

process.on("SIGTERM", () => { try { fs.unlinkSync(path.join(dir, "pid")); } catch {} process.exit(0); });
connect();
