(function () {
  var table = document.getElementById("listing");
  var tbody = table.tBodies[0];
  var filter = document.getElementById("filter");
  var count = document.getElementById("count");
  var heads = table.tHead.rows[0].cells;
  var parent = tbody.rows[0];
  var rows = Array.prototype.slice.call(tbody.rows, 1);
  var col = "name", dir = 1;

  function key(tr) {
    var v = tr.dataset[col === "name" ? "name" : col];
    return col === "size" || col === "date" ? Number(v || 0) : (v || "");
  }

  function sortRows() {
    rows.sort(function (a, b) {
      var x = key(a), y = key(b);
      if (x < y) return -dir;
      if (x > y) return dir;
      return a.dataset.name < b.dataset.name ? -1 : 1;
    });
    rows.forEach(function (tr) { tbody.appendChild(tr); });
    applyFilter();
  }

  function applyFilter() {
    var q = filter.value.trim().toLowerCase();
    var shown = 0;
    rows.forEach(function (tr) {
      var ok = !q || tr.dataset.name.indexOf(q) !== -1 || tr.dataset.hash.indexOf(q) !== -1;
      tr.classList.toggle("hidden", !ok);
      if (ok) shown++;
    });
    count.textContent = shown + (shown === 1 ? " item" : " items") + (q ? " of " + rows.length : "");
  }

  function setSort(th) {
    var c = th.dataset.col;
    dir = col === c ? -dir : 1;
    col = c;
    Array.prototype.forEach.call(heads, function (h) { h.removeAttribute("aria-sort"); });
    th.setAttribute("aria-sort", dir === 1 ? "ascending" : "descending");
    sortRows();
  }

  Array.prototype.forEach.call(heads, function (th) {
    if (!th.classList.contains("sortable")) return;
    th.addEventListener("click", function () { setSort(th); });
    th.addEventListener("keydown", function (e) {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); setSort(th); }
    });
  });

  filter.addEventListener("input", applyFilter);

  // Force download for .sh / SHA256SUMS links via Blob
  document.querySelectorAll("a.dl-link").forEach(function (a) {
    a.addEventListener("click", function (e) {
      e.preventDefault();
      var href = this.getAttribute("href");
      fetch(href)
        .then(function (res) {
          if (!res.ok) throw new Error(res.status);
          return res.blob();
        })
        .then(function (blob) {
          var url = URL.createObjectURL(blob);
          var temp = document.createElement("a");
          temp.href = url;
          temp.download = href.split("/").pop();
          document.body.appendChild(temp);
          temp.click();
          document.body.removeChild(temp);
          URL.revokeObjectURL(url);
        })
        .catch(function () {
          // fallback: open directly
          window.location.href = href;
        });
    });
  });

  sortRows();
  if (parent) parent.classList.remove("hidden");
})();
