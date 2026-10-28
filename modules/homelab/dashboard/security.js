// Security panel (modules/homelab/dashboard.nix): bans and failed logins from security.json,
// with an Unban button per active ban. Opened by the Security tile (href "#security") or by
// visiting dash.home.lab/#security (the ban notifications link there).
//
// Everything shown here comes from people trying to log in (addresses, usernames), so it is
// only ever inserted as text, never as HTML.
(() => {
  const KINDS = {
    password: "wrong password",
    "api key": "wrong API key",
    "2fa": "wrong 2FA code — the password was right",
    admin: "admin token",
    ssh: "SSH login",
  };

  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined && text !== null) node.textContent = String(text);
    return node;
  }

  function relative(iso) {
    if (!iso) return "unknown";
    const seconds = (new Date(iso).getTime() - Date.now()) / 1000;
    const abs = Math.abs(seconds);
    const [value, unit] =
      abs < 90 ? [Math.round(abs), "s"]
      : abs < 5400 ? [Math.round(abs / 60), "m"]
      : abs < 172800 ? [Math.round(abs / 3600), "h"]
      : [Math.round(abs / 86400), "d"];
    return seconds < 0 ? `${value}${unit} ago` : `in ${value}${unit}`;
  }

  function absolute(iso) {
    return iso ? new Date(iso).toLocaleString() : "";
  }

  function notify(kind, title, detail) {
    // Same toasts as the wake/sleep buttons (defined in the main dashboard script)
    if (typeof window.zToast === "function") window.zToast(kind, title, detail);
  }

  // POST to a webhook hook (Caddy routes /hooks/* to the Pi's webhook). The custom header is
  // what the hook checks for; browsers won't send it cross-site without a CORS preflight.
  function hook(name, action, body) {
    return fetch(`/hooks/${name}`, {
      method: "POST",
      credentials: "same-origin",
      headers: { "Content-Type": "application/json", "X-Homelab-Action": action },
      body: JSON.stringify(body || {}),
    });
  }

  async function load(refresh) {
    if (refresh) {
      try {
        await hook("security-refresh", "refresh");
      } catch (err) {
        // Fall back to the file as the timer last wrote it
      }
    }
    const res = await fetch(`/status/security.json?t=${Date.now()}`, {
      credentials: "same-origin",
      cache: "no-store",
    });
    if (!res.ok) throw new Error(`security.json: HTTP ${res.status}`);
    return res.json();
  }

  let dialog = null;
  let body = null;
  let meta = null;
  let lastFocus = null;

  function build() {
    dialog = el("div", "z-modal");
    dialog.setAttribute("role", "dialog");
    dialog.setAttribute("aria-modal", "true");
    dialog.setAttribute("aria-labelledby", "z-security-title");
    dialog.hidden = true;

    const panel = el("div", "z-modal-panel");
    const head = el("div", "z-modal-head");
    const titles = el("div");
    const title = el("h2", null, "Security");
    title.id = "z-security-title";
    meta = el("p", "z-modal-meta", "");
    titles.append(title, meta);

    const refresh = el("button", "z-btn", "Refresh");
    refresh.type = "button";
    refresh.addEventListener("click", () => show(true));
    const close = el("button", "z-btn z-btn-icon", "×");
    close.type = "button";
    close.setAttribute("aria-label", "Close");
    close.addEventListener("click", hide);
    const actions = el("div", "z-modal-actions");
    actions.append(refresh, close);
    head.append(titles, actions);

    body = el("div", "z-modal-body");
    panel.append(head, body);
    dialog.append(panel);
    dialog.addEventListener("click", (e) => {
      if (e.target === dialog) hide();
    });
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && dialog && !dialog.hidden) hide();
    });
    document.body.appendChild(dialog);
  }

  function hide() {
    if (!dialog) return;
    dialog.hidden = true;
    document.documentElement.classList.remove("z-modal-open");
    if (location.hash === "#security") {
      history.replaceState(null, "", location.pathname + location.search);
    }
    if (lastFocus) lastFocus.focus();
  }

  function message(text, className) {
    body.replaceChildren(el("p", className || "z-empty", text));
  }

  async function show(refresh) {
    if (!dialog) build();
    if (dialog.hidden) {
      lastFocus = document.activeElement;
      dialog.hidden = false;
      document.documentElement.classList.add("z-modal-open");
      dialog.querySelector(".z-btn-icon").focus();
    }
    if (!body.firstChild) message("Loading…");
    try {
      render(await load(refresh));
    } catch (err) {
      message(`Could not load security status: ${err.message}`, "z-empty z-error");
    }
  }

  function chip(text, className) {
    return el("span", `z-chip ${className || ""}`.trim(), text);
  }

  function banRow(ban) {
    const row = el("li", `z-row${ban.active ? "" : " z-row-dim"}`);

    const main = el("div", "z-row-main");
    const line = el("div", "z-row-line");
    line.append(el("code", "z-ip", ban.ip), chip(ban.jail));
    if (ban.kinds.includes("2fa")) line.append(chip("2FA", "z-chip-bad"));
    main.append(line);

    const who = ban.users.length
      ? ban.users.join(", ")
      : ban.kinds.includes("2fa") ? "account not logged" : "account unknown";
    const what = ban.kinds.map((k) => KINDS[k] || k).join(", ");
    main.append(el("div", "z-row-sub", what ? `${who} · ${what}` : who));

    const when = [`banned ${relative(ban.bannedAt)}`];
    if (ban.active) when.push(ban.expiresAt ? `until ${relative(ban.expiresAt)}` : "permanent");
    else if (ban.unbannedAt) when.push(`unbanned ${relative(ban.unbannedAt)}`);
    else when.push("expired");
    if (ban.failures) when.push(`${ban.failures} failed`);
    if (ban.banCount > 1) when.push(`ban #${ban.banCount}`);
    const sub = el("div", "z-row-sub", when.join(" · "));
    sub.title = absolute(ban.bannedAt);
    main.append(sub);
    row.append(main);

    if (ban.active) {
      const button = el("button", "z-btn z-btn-ok", "Unban");
      button.type = "button";
      button.addEventListener("click", () => unban(ban, button));
      row.append(button);
    }
    return row;
  }

  // One row per address, account and kind of failure, newest first
  function groupAttempts(attempts) {
    const groups = new Map();
    for (const a of attempts) {
      const key = `${a.ip}|${a.user || ""}|${a.kind}`;
      const g = groups.get(key);
      if (g) {
        g.count += 1;
        if (a.time < g.first) g.first = a.time;
      } else {
        groups.set(key, { ...a, count: 1, first: a.time });
      }
    }
    return [...groups.values()];
  }

  function attemptRow(a) {
    const row = el("li", "z-row");
    const main = el("div", "z-row-main");
    const line = el("div", "z-row-line");
    line.append(el("code", "z-ip", a.ip));
    if (a.count > 1) line.append(el("span", "z-times", `×${a.count}`));
    if (a.banned) line.append(chip("banned", "z-chip-bad"));
    if (a.trusted) line.append(chip("tailnet/LAN · never banned"));
    main.append(line);
    const who = a.user || (a.kind === "2fa" ? "account not logged" : "account unknown");
    main.append(el("div", "z-row-sub", `${who} · ${KINDS[a.kind] || a.kind}`));
    row.append(main);
    const time = el("span", "z-row-time", relative(a.time));
    time.title = a.count > 1 ? `${absolute(a.first)} – ${absolute(a.time)}` : absolute(a.time);
    row.append(time);
    return row;
  }

  function section(title, count, items, empty, makeRow) {
    const wrap = el("section", "z-section");
    const h = el("h3", null, title);
    h.append(el("span", "z-count", count));
    wrap.append(h);
    if (!items.length) {
      wrap.append(el("p", "z-empty", empty));
    } else {
      const list = el("ul", "z-list");
      items.forEach((item) => list.append(makeRow(item)));
      wrap.append(list);
    }
    return wrap;
  }

  function render(data) {
    const s = data.summary || {};
    meta.textContent = `${data.fail2ban ? s.status : "fail2ban is not running"} · blocking at ${data.edge} · updated ${relative(data.generated)}`;
    const active = data.bans.filter((b) => b.active);
    const past = data.bans.filter((b) => !b.active);
    const attempts = groupAttempts(data.attempts);
    body.replaceChildren(
      section("Banned", active.length, active, "Nothing is banned.", banRow),
      section("Failed logins, last 24 hours", data.attempts.length, attempts, "No failed logins.", attemptRow),
      section("Earlier bans, last 7 days", past.length, past, "None.", banRow),
    );
  }

  async function unban(ban, button) {
    if (!confirm(`Unban ${ban.ip} (${ban.jail})?`)) return;
    button.disabled = true;
    button.textContent = "Unbanning…";
    try {
      const res = await hook("unban", "unban", { jail: ban.jail, ip: ban.ip });
      const text = (await res.text()).trim();
      if (!res.ok) throw new Error(text || `HTTP ${res.status}`);
      notify("ok", `Unbanned ${ban.ip}`, text);
      await show(false);
    } catch (err) {
      notify("fail", `Unban ${ban.ip} failed`, err.message);
      button.disabled = false;
      button.textContent = "Unban";
    }
  }

  document.addEventListener("click", (e) => {
    const link = e.target.closest('a[href="#security"]');
    if (!link) return;
    e.preventDefault();
    e.stopPropagation();
    show(true);
  });

  function openFromHash() {
    if (location.hash === "#security") show(true);
  }
  window.addEventListener("hashchange", openFromHash);
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", openFromHash);
  else openFromHash();
})();
