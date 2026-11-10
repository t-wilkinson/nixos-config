// Minecraft tiles (modules/homelab/dashboard.nix, mc-server.nix): one tile per server plus
// "Off". Clicking one switches the PC to that server; the running one is marked, and each tile's
// widget shows its status. Hooks: /hooks/mc-status (GET, JSON) and /hooks/mc-switch-<name>
// (POST), which Caddy routes to the PC's webhook.
(() => {
  const PREFIX = "#mc-switch-";
  let last = null;

  function notify(kind, title, detail) {
    if (typeof window.zToast === "function") window.zToast(kind, title, detail);
  }

  function tiles() {
    return [...document.querySelectorAll(`a[href^="${PREFIX}"]`)]
      .map((link) => ({ name: link.getAttribute("href").slice(PREFIX.length), card: link.closest(".service-card") }))
      .filter((t) => t.card);
  }

  // data-mc-state: online / starting / stopping / failed on the server's tile; data-mc-selected
  // on the one that will run (also "off" when everything is stopped by choice)
  function mark(data) {
    last = data;
    for (const { name, card } of tiles()) {
      const s = data && data.servers && data.servers[name];
      const state = s && s.status !== "Off" ? s.status.toLowerCase() : null;
      state ? card.setAttribute("data-mc-state", state) : card.removeAttribute("data-mc-state");
      data && data.selected === name ? card.setAttribute("data-mc-selected", "") : card.removeAttribute("data-mc-selected");
    }
  }

  async function refresh() {
    try {
      const res = await fetch(`/hooks/mc-status?t=${Date.now()}`, { credentials: "same-origin" });
      if (!res.ok) throw new Error(String(res.status));
      mark(await res.json());
    } catch (err) {
      mark(null); // PC asleep or unreachable
    }
  }

  document.addEventListener("click", async (e) => {
    const link = e.target.closest(`a[href^="${PREFIX}"]`);
    if (!link) return;
    e.preventDefault();
    e.stopPropagation();

    const name = link.getAttribute("href").slice(PREFIX.length);
    const label = (last && last.servers && last.servers[name] && last.servers[name].label) || name;
    const running = last && last.running && last.servers[last.running];
    if (last && last.running === name) {
      notify("ok", `${label} is already running`, running.status);
      return;
    }
    const kicks = running ? ` Anyone on ${running.label} will be disconnected.` : "";
    const question = name === "off" ? `Stop the Minecraft server?${kicks}` : `Switch Minecraft to ${label}?${kicks}`;
    if (!confirm(question)) return;

    const card = link.closest(".service-card");
    card && card.setAttribute("data-hook-state", "busy");
    try {
      const res = await fetch(`/hooks/mc-switch-${name}`, {
        method: "POST",
        credentials: "same-origin",
        headers: { "X-Homelab-Action": "mc-switch" },
      });
      const text = (await res.text()).trim();
      if (res.ok) {
        notify("ok", name === "off" ? "Minecraft: stopping" : `Minecraft: starting ${label}`, "Big packs take a few minutes to load");
        card && card.setAttribute("data-hook-state", "ok");
      } else {
        notify("fail", `Switch failed (${res.status})`, text);
        card && card.setAttribute("data-hook-state", "fail");
      }
    } catch (err) {
      notify("fail", "Switch failed: is the PC awake?", err.message);
      card && card.setAttribute("data-hook-state", "fail");
    }
    setTimeout(() => card && card.removeAttribute("data-hook-state"), 3000);
    setTimeout(refresh, 1500);
  });

  // Homepage renders the tiles after this script runs (and may re-render them): mark new ones
  new MutationObserver(() => {
    const fresh = tiles().filter((t) => !t.card.hasAttribute("data-mc-seen"));
    if (!fresh.length) return;
    fresh.forEach((t) => t.card.setAttribute("data-mc-seen", ""));
    mark(last);
  }).observe(document.documentElement, { childList: true, subtree: true });
  refresh();
  setInterval(refresh, 10000);
})();
