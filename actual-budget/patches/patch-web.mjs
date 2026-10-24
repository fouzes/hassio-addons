#!/usr/bin/env node
// Make Actual Budget's web client work under a URL prefix.
//
// Actual is built for the root of a host and has no base-path setting, but
// Home Assistant ingress serves an add-on under /api/hassio_ingress/<token>/.
// This rewrites the compiled client at image build time so that it resolves
// every address against the document's <base> tag instead of "/". nginx writes
// the real prefix into that tag per request (see nginx/ingress.conf); when the
// client is opened on the add-on port the tag stays "/" and nothing changes.
//
// The client is minified, so every substitution states how many matches it
// expects and the build fails if upstream changed the code it was written for.
// Review this file whenever ACTUAL_VERSION changes.
//
// Usage: patch-web.mjs <web-root> <shim-file>
import { copyFileSync, existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";

class PatchError extends Error {}

const [root, shim] = process.argv.slice(2);
if (!root || !shim || !existsSync(join(root, "index.html"))) {
  console.error("usage: patch-web.mjs <web-root> <shim-file>");
  process.exit(2);
}

const read = (path) => readFileSync(path, "utf8");

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) =>
    entry.isDirectory() ? walk(join(dir, entry.name)) : [join(dir, entry.name)],
  );
}

// Apply a regular expression to a file and insist on the number of matches.
function substitute(path, pattern, replacement, expected) {
  const text = read(path);
  const found = [...text.matchAll(new RegExp(pattern.source, `${pattern.flags}g`))].length;
  if (found !== expected) {
    throw new PatchError(
      `${basename(path)}: expected ${expected} match(es) of ${pattern}, found ${found}`,
    );
  }
  writeFileSync(path, text.replace(new RegExp(pattern.source, `${pattern.flags}g`), replacement));
}

// Find the single file whose name matches, or whose content matches.
function only(paths, description) {
  if (paths.length !== 1) {
    throw new PatchError(
      `expected exactly one ${description}, found ${paths.length}: ${paths.map((p) => basename(p))}`,
    );
  }
  return paths[0];
}

let entryBundle;
const scripts = walk(root).filter((path) => path.endsWith(".js"));
const indexHtml = join(root, "index.html");

// --- index.html -----------------------------------------------------------
// Every bundle, icon and the manifest is linked by a root-relative address.
// Make them relative, state the base before the first of them and load the
// shim that exports it. The shim is a file because the server sends a content
// security policy of script-src 'self'.
{
  let text = read(indexHtml);
  const entry = text.match(/<script type="module"[^>]*\ssrc="\/(static\/js\/index\.[^"]+\.js)"/);
  if (!entry) throw new PatchError("index.html does not load an entry bundle where expected");
  entryBundle = join(root, entry[1]);

  const before = text.length;
  text = text.replace(/(href|src)="\/(?!\/)/g, '$1="');
  if (text.length === before) throw new PatchError("index.html: no root-relative addresses found");
  const left = text.match(/=["']\/(?!\/)/g);
  if (left) throw new PatchError(`index.html: ${left.length} address(es) still point at the root`);

  if ((text.match(/<head>/g) || []).length !== 1) throw new PatchError("index.html: no single <head>");
  text = text.replace("<head>", `<head>\n    <base href="/">\n    <script src="${basename(shim)}"></script>`);
  writeFileSync(indexHtml, text);
}

// --- Entry bundle ---------------------------------------------------------
// The backend worker lives next to the bundle, so address it from the bundle.
substitute(
  entryBundle,
  /new URL\(`\/static\/js\/(browser-server\.[A-Za-z0-9_-]+\.js)`/,
  "new URL(`./$1`",
  1,
);
// The SharedWorker is addressed by the document.
substitute(
  entryBundle,
  /new SharedWorker\(`\/static\/(shared-browser-server-[A-Za-z0-9_-]+\.js)`/,
  "new SharedWorker(window.__actualBasePath+`static/$1`",
  1,
);
// Workers have no document, so the client passes them the site root.
substitute(entryBundle, /publicUrl:`\/`\.slice\(0,-1\)/, "publicUrl:window.__actualBasePath.slice(0,-1)", 1);
// Without a basename the router reads the prefix as a route and matches nothing.
substitute(
  entryBundle,
  /BrowserRouter,\{children:/,
  "BrowserRouter,{basename:window.__actualBasePath,children:",
  1,
);
// The service worker is registered against the site root, which under ingress
// is Home Assistant's. It only caches the app for offline use, which a server
// that needs Home Assistant to be reachable cannot use.
substitute(
  entryBundle,
  /async function register\(\)\{if\(`serviceWorker`in navigator\)\{/,
  "async function register(){if(!1){",
  1,
);

// --- Vite's preload helper ------------------------------------------------
// Preload hints for lazy chunks are built from the site root. Which bundle
// holds the helper changes between releases, so search for it.
{
  const pattern = /assetsURL=function\((\w+)\)\{return`\/`\+\1\}/;
  const helper = only(
    scripts.filter((path) => pattern.test(read(path))),
    "bundle with Vite's preload helper",
  );
  substitute(helper, pattern, "assetsURL=function($1){return window.__actualBasePath+$1}", 1);
}

// --- Stylesheets and manifests -------------------------------------------
// A stylesheet in static/css/ reaches the fonts one directory up; manifests
// name icons and the start address from the root.
{
  const stylesheets = walk(join(root, "static", "css")).filter((path) => path.endsWith(".css"));
  if (!stylesheets.length) throw new PatchError("no stylesheets found under static/css");
  let rewritten = 0;
  for (const path of stylesheets) {
    let text = read(path);
    text = text.replace(/url\(\/static\//g, () => (rewritten++, "url(../"));
    const left = text.match(/url\(\/(?!\/)/g);
    if (left) throw new PatchError(`${basename(path)}: ${left.length} address(es) still point at the root`);
    writeFileSync(path, text);
  }
  if (!rewritten) throw new PatchError("no root-relative addresses found in the stylesheets");

  const manifests = readdirSync(root).filter((name) => name.endsWith(".webmanifest"));
  if (!manifests.length) throw new PatchError("no web app manifest found");
  rewritten = 0;
  for (const name of manifests) {
    let text = read(join(root, name));
    text = text.replace(/"\/(?!\/)/g, () => (rewritten++, '"./'));
    writeFileSync(join(root, name), text);
  }
  if (!rewritten) throw new PatchError("no root-relative addresses found in the manifests");
}

// --- Origin ---------------------------------------------------------------
// The client looks for its server at window.location.origin, which under
// ingress lacks the prefix. Also used for the OpenID redirect address.
{
  let replaced = 0;
  for (const path of scripts) {
    const text = read(path);
    const count = text.split("window.location.origin").length - 1;
    if (!count) continue;
    replaced += count;
    writeFileSync(
      path,
      text.replaceAll("window.location.origin", "(window.location.origin+window.__actualBasePath.slice(0,-1))"),
    );
  }
  if (!replaced) throw new PatchError("no references to window.location.origin found");
}

// --- Workers --------------------------------------------------------------
// The backend worker receives the site root in its init message; keep it where
// the database worker it imports can read it.
const backendWorker = only(
  scripts.filter((path) => /^browser-server\.[A-Za-z0-9_-]+\.js$/.test(basename(path))),
  "backend worker (static/js/browser-server.<hash>.js)",
);
substitute(
  backendWorker,
  /const hash = msg\.hash;/,
  "const hash = msg.hash;\n        self.__actualPublicUrl = msg.publicUrl || '';",
  1,
);
// The database worker loads SQLite's WebAssembly build and its seed files.
const databaseWorker = only(
  scripts.filter((path) => /^kcab\.worker\.[A-Za-z0-9_-]+\.js$/.test(basename(path))),
  "database worker (kcab/kcab.worker.<hash>.js)",
);
substitute(
  databaseWorker,
  /fetch\(`\/data-file-index\.txt`\)/,
  "fetch((self.__actualPublicUrl||``)+`/data-file-index.txt`)",
  1,
);
substitute(
  databaseWorker,
  /fetchFile\(`\/data\/`\+file\)/,
  "fetchFile((self.__actualPublicUrl||``)+`/data/`+file)",
  1,
);
substitute(
  databaseWorker,
  /\{baseURL=`\/`,wasmBinary=/,
  "{baseURL=(self.__actualPublicUrl||``)+`/`,wasmBinary=",
  1,
);

copyFileSync(shim, join(root, basename(shim)));
console.log(`Patched the Actual web client in ${root}`);
