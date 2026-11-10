# Minecraft servers

Three servers run on the PC, one at a time, all on port 25565 (`mc.home.lab`, `10.1.0.1`, or the
PC's Wi-Fi address). Starting one stops whichever is running.

| Server     | What                                            | World share on the Pi          |
|------------|-------------------------------------------------|--------------------------------|
| `paper`    | Paper 1.21.11, your existing worlds             | `/var/lib/minecraft`           |
| `oneblock` | OneBlock Reborn map + mods (Fabric 1.21.11)     | `/var/lib/minecraft-oneblock`  |
| `atm10`    | All the Mods 10 server pack (NeoForge 1.21.1)   | `/var/lib/minecraft-atm10`     |

- `../mc-server.nix`: containers, switching, dashboard hooks
- `packs.nix`: versions, download URLs and hashes for each server
- `oneblock/mods.json`: the OneBlock mod list (edit this)
- `oneblock/modrinth.index.json`: the locked list (generated; Nix reads it)
- `update-modpack.py`: makes the second from the first

## Switching

On the PC:

```sh
mc-switch                 # what's selected and running
sudo mc-switch oneblock   # paper | oneblock | atm10 | off
sudo mc-switch logs -f      # the selected server's log; also works after it failed
```

Or use the Minecraft tiles on the dashboard. The choice is kept across reboots.

Console commands go to whichever server is running:

```sh
sudo mc-switch cmd 'op YourName'
sudo mc-switch cmd 'gamerule playersSleepingPercentage 50'
```

## Turning on OneBlock and ATM10

A server stays off, with a build warning naming the fix, until its downloads are pinned. Run these
on a machine with internet access (the PC):

1. Lock the OneBlock mods, then look at what it reports:

   ```sh
   python3 modules/homelab/minecraft/update-modpack.py modules/homelab/minecraft/oneblock
   ```

   Mods marked `"optional"` in `mods.json` are skipped with a warning if they have no 1.21.11
   Fabric build yet. Others stop the script. Remove a mod, mark it optional, or change
   `"minecraft"` to a version they all support. (The OneBlock Reborn map is for 1.21.11, so
   prefer dropping mods.)

2. Pin the two downloads (the commands are also in the build warnings). Put each result in
   `packs.nix` as `hash = "sha256-...";`:

   ```sh
   nix store prefetch-file --json 'https://mediafilez.forgecdn.net/files/7335/453/OneBlock%20Reborn%201.2.4.zip' | jq -r .hash
   nix store prefetch-file --json 'https://mediafilez.forgecdn.net/files/9366/998/ServerFiles-8.4.zip' | jq -r .hash
   ```

   If a URL 404s (CurseForge sometimes renames files), download the file from its CurseForge page
   and add it under the name `packs.nix` uses:

   ```sh
   nix-prefetch-url --name oneblock-reborn-1.2.4.zip "file://$PWD/OneBlock Reborn 1.2.4.zip"
   nix hash convert --hash-algo sha256 --to sri <the printed hash>
   ```

3. Rebuild the Pi (the dashboard and client download), then the PC.

## Players

**OneBlock** needs the same mods on each computer. Download the client pack from the dashboard
("OneBlock client pack", or `https://dash.home.lab/minecraft/oneblock.mrpack`) and import it in
the Modrinth App or Prism Launcher. After you change `mods.json`, bump its `"version"`, re-run
the script, rebuild, and re-import the pack.

**ATM10**: install "All the Mods 10" version 8.4 from the CurseForge app, Prism or the ATM
launcher. The version has to match the server.

**Paper**: vanilla 1.21.11.

## Updating ATM10

In `packs.nix`, change `version`, `fileId`, `fileName` and `neoforge` (from the release's
changelog), set `hash = null`, rebuild to get the warning with the new URL, and prefetch as above.
On the first start of a new version the server replaces `config/`, `defaultconfigs/`, `kubejs/`
etc. with the pack's copies. The world and `server.properties` are kept. The Pi's nightly borg
backup has the old copies.

## Notes

- `server-port`, RCON, `online-mode` and `motd` are set on every start, so borg's
  `save-all`/`save-off` works on whichever server is up. Change anything else in each world's
  `server.properties`.
- `online-mode=false` (`data.onlineMode` in `../mc-server.nix`) lets anyone who reaches the port
  join under any name. Keep the port LAN/tailnet only while it's false.
- Mods come from the Nix store (`mods` is a symlink). Don't drop jars into it. Add them to
  `mods.json` instead.
