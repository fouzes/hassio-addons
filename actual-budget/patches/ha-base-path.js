/*
 * Exports the path the page is served under, as written into the <base> tag
 * (by nginx under Home Assistant ingress, "/" on the add-on port). The patched
 * client resolves all of its addresses against it. Always ends in a slash.
 */
window.__actualBasePath = new URL(".", document.baseURI).pathname;

/*
 * Actual keeps its budget in SQLite compiled to WebAssembly and needs a
 * SharedArrayBuffer, which browsers only provide to a cross-origin isolated
 * page. Inside Home Assistant's ingress frame the page is not isolated and no
 * header this server sends can change that, so Actual would stop on a page
 * asking the user to confirm its fallback. Confirm it here. The cost is that
 * the budget cannot be open in two tabs at once.
 */
if (window.__actualBasePath !== "/") {
  try {
    window.localStorage.setItem("SharedArrayBufferOverride", "true");
  } catch (err) {
    /* No storage available; Actual then asks the question itself. */
  }
}
