pragma Singleton

import QtQuick
import Quickshell

// Installed apps, searched by name, generic name and keywords (used by Launcher.qml and the
// overview's search box). Names that start with the query come first.
Singleton {
    function search(query) {
        const q = query.toLowerCase().trim();
        const apps = Array.from(DesktopEntries.applications.values).filter(e => !e.noDisplay);
        if (q === "")
            return apps.sort((a, b) => a.name.localeCompare(b.name));
        const scored = [];
        for (const app of apps) {
            const name = app.name.toLowerCase();
            let score = -1;
            if (name.startsWith(q))
                score = 0;
            else if (name.includes(q))
                score = 1;
            else if ((app.genericName || "").toLowerCase().includes(q) || app.keywords.some(k => k.toLowerCase().includes(q)))
                score = 2;
            if (score >= 0)
                scored.push({ app, score });
        }
        scored.sort((a, b) => a.score - b.score || a.app.name.localeCompare(b.app.name));
        return scored.map(s => s.app);
    }

    // Icon for a window's class (app id), via its desktop entry when there is one
    function iconFor(appClass) {
        const entry = DesktopEntries.heuristicLookup(appClass);
        return Quickshell.iconPath(entry ? entry.icon : appClass, "application-x-executable");
    }
}
