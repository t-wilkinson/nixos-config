"""Check config/quickshell: load it with stand-in Quickshell modules (mods/) and report every QML warning or error.

Usage: python3 run.py <config dir>
"""
import enum
import os
import shutil
import sys
import tempfile

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")

from PySide6.QtCore import (QAbstractListModel, QModelIndex, QObject, Property, QTimer,
                            Qt, QtMsgType, Signal, qInstallMessageHandler)
from PySide6.QtCore import QPoint, QPointF
from PySide6.QtGui import QGuiApplication, QWheelEvent
from PySide6.QtQml import (QmlAttached, QmlElement, QmlUncreatable, QQmlComponent,
                           QQmlEngine, QJSValue)
from PySide6.QtCore import QEnum, QMetaObject, Q_ARG

HERE = os.path.dirname(os.path.abspath(__file__))
messages = []


def handler(mode, context, message):
    kind = {QtMsgType.QtDebugMsg: "debug", QtMsgType.QtInfoMsg: "info",
            QtMsgType.QtWarningMsg: "WARNING", QtMsgType.QtCriticalMsg: "ERROR",
            QtMsgType.QtFatalMsg: "FATAL"}.get(mode, "?")
    messages.append((kind, message))


qInstallMessageHandler(handler)

# ---- Quickshell.Wayland: attached layer-shell properties and enums ----
QML_IMPORT_NAME = "Quickshell.Wayland"
QML_IMPORT_MAJOR_VERSION = 1


class LayershellAttached(QObject):
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._layer = 2
        self._ns = ""
        self._kb = 0

    def _get_layer(self): return self._layer
    def _set_layer(self, v): self._layer = v
    layer = Property(int, _get_layer, _set_layer, notify=changed)

    def _get_ns(self): return self._ns
    def _set_ns(self, v): self._ns = v
    namespace = Property(str, _get_ns, _set_ns, notify=changed)

    def _get_kb(self): return self._kb
    def _set_kb(self, v): self._kb = v
    keyboardFocus = Property(int, _get_kb, _set_kb, notify=changed)


@QmlElement
@QmlUncreatable("attached only")
@QmlAttached(LayershellAttached)
class WlrLayershell(QObject):
    @staticmethod
    def qmlAttachedProperties(cls, obj):
        return LayershellAttached(obj)


@QmlElement
@QmlUncreatable("enum")
class WlrLayer(QObject):
    @QEnum
    class Enum(enum.IntEnum):
        Background = 0
        Bottom = 1
        Top = 2
        Overlay = 3


@QmlElement
@QmlUncreatable("enum")
class WlrKeyboardFocus(QObject):
    @QEnum
    class Enum(enum.IntEnum):
        None_ = 0
        Exclusive = 1
        OnDemand = 2


from PySide6.QtQuick import QQuickItem
QML_IMPORT_NAME = "Quickshell.Wayland"


@QmlElement
class ScreencopyView(QQuickItem):
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._src = None
        self._live = False

    def _get_src(self): return self._src
    def _set_src(self, v): self._src = v; self.changed.emit()
    captureSource = Property(QObject, _get_src, _set_src, notify=changed)

    def _get_live(self): return self._live
    def _set_live(self, v): self._live = v; self.changed.emit()
    live = Property(bool, _get_live, _set_live, notify=changed)


# ---- Harness: a list model like Quickshell's ObjectModel (modelData role + values) ----
QML_IMPORT_NAME = "Harness"


@QmlElement
class ObjectListModel(QAbstractListModel):
    valuesChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._values = []

    def roleNames(self):
        return {Qt.UserRole + 1: b"modelData"}

    def rowCount(self, parent=QModelIndex()):
        return len(self._values)

    def data(self, index, role):
        if role == Qt.UserRole + 1 and 0 <= index.row() < len(self._values):
            return self._values[index.row()]
        return None

    def _get(self):
        return self._values

    def _set(self, v):
        self.beginResetModel()
        self._values = list(v) if v is not None else []
        self.endResetModel()
        self.valuesChanged.emit()

    values = Property("QVariantList", _get, _set, notify=valuesChanged)


@QmlElement
class MockWorkspace(QObject):
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._id = 0
        self._toplevels = ObjectListModel(self)

    def _get_id(self): return self._id
    def _set_id(self, v): self._id = v; self.changed.emit()
    id = Property(int, _get_id, _set_id, notify=changed)

    def _get_n(self): return len(self._toplevels._values)
    def _set_n(self, n): self._toplevels._set([self] * n)
    windows = Property(int, _get_n, _set_n, notify=changed)

    def _get_t(self): return self._toplevels
    toplevels = Property(QObject, _get_t, constant=True)


def main():
    src = sys.argv[1]
    work = tempfile.mkdtemp()
    shell = os.path.join(work, "shell")
    shutil.copytree(src, shell)
    # Quickshell finds singletons by `pragma Singleton`; plain Qt needs a qmldir
    lines = ["module shell"]
    for f in sorted(os.listdir(shell)):
        if f.endswith(".qml") and f != "shell.qml":
            name = f[:-4]
            text = open(os.path.join(shell, f)).read()
            prefix = "singleton " if "pragma Singleton" in text else ""
            lines.append(f"{prefix}{name} 1.0 {f}")
    open(os.path.join(shell, "qmldir"), "w").write("\n".join(lines) + "\n")
    os.makedirs("/tmp/harness-home/.local/state/theme", exist_ok=True)

    app = QGuiApplication(sys.argv)
    engine = QQmlEngine()
    engine.addImportPath(os.path.join(HERE, "mods"))
    engine.warnings.connect(lambda ws: [messages.append(("QML", w.toString())) for w in ws])

    comp = QQmlComponent(engine)
    comp.loadUrl("file://" + os.path.join(shell, "shell.qml"))
    if comp.isError():
        for e in comp.errors():
            print("LOAD ERROR:", e.toString())
        return 1
    root = comp.create()
    if root is None:
        for e in comp.errors():
            print("CREATE ERROR:", e.toString())
        return 1

    probe = QQmlComponent(engine)
    probe_src = 'import QtQuick\nimport Quickshell.Services.Pipewire\nimport Quickshell.Hyprland\nimport "file://' + shell + '"\nQtObject { property var s: ShellState; property var t: Theme; property var b: Brightness; property real vol: Pipewire.defaultAudioSink.audio.volume; function clear() { s.clearNotifications(); } function brightness() { const m = b.ddc["DP-1"]; console.log("HARNESS: brightness monitors=" + Object.keys(b.ddc) + " DP-1 bus=" + (m ? m.bus : "-") + " value=" + (m ? m.value.toFixed(2) : "-")) } function builtin() { b.adjust("eDP-1", -0.05) } function ipcUp() { b.adjustFocused(b.step) } function hypr(name, data) { Hyprland.rawEvent({ name: name, data: data }) } function report() { console.log("HARNESS: theme surface=" + t.colors.surface + " surfaceText=" + t.colors.surfaceText + " red=" + t.colors.red) } }\n'
    probe.setData(probe_src.encode(), "file://" + shell + "/probe.qml")
    pobj = probe.create()
    if pobj is None:
        print("PROBE ERROR:", [e.toString() for e in probe.errors()])
        return 1
    state = pobj.property("s")
    theme = pobj.property("t")

    steps = [
        ("open overview", lambda: state.setProperty("overviewOpen", True)),
        ("close overview", lambda: state.setProperty("overviewOpen", False)),
        ("open sidebar", lambda: state.setProperty("sidebarOpen", True)),
        ("close sidebar", lambda: state.setProperty("sidebarOpen", False)),
        ("open launcher", lambda: state.setProperty("launcherOpen", True)),
        ("close launcher", lambda: state.setProperty("launcherOpen", False)),
        ("open power menu", lambda: state.setProperty("powerMenuOpen", True)),
        ("close power menu", lambda: state.setProperty("powerMenuOpen", False)),
        ("open sidebar again", lambda: state.setProperty("sidebarOpen", True)),
        ("toggle dnd", lambda: state.setProperty("dnd", True)),
        ("theme values", lambda: QMetaObject.invokeMethod(pobj, "report")),
        ("screenshot of the bar (HARNESS_SCREENSHOT=file.png)", lambda: screenshot()),
        ("brightness detected", lambda: QMetaObject.invokeMethod(pobj, "brightness")),
        ("scroll up at the top edge, left half (brightness)", lambda: wheel(0.15, 1, 120)),
        ("scroll up again, as touchpad fractions", lambda: [wheel(0.15, 1, 40) for _ in range(3)]),
        ("brightness after scrolling", lambda: QMetaObject.invokeMethod(pobj, "brightness")),
        ("scroll down at the top edge, right half (volume)", lambda: wheel(0.85, 1, -120)),
        ("volume after scrolling", lambda: print_volume()),
        ("scroll over the workspaces", lambda: wheel(0.5, 25, -120)),
        ("scroll down, then up, over the media", lambda: [wheel_on("MediaWidget", -120), wheel_on("MediaWidget", 120)]),
        ("brightness key (ipc up)", lambda: QMetaObject.invokeMethod(pobj, "ipcUp")),
        ("built-in screen (brightnessctl)", lambda: QMetaObject.invokeMethod(pobj, "builtin")),
        ("another app asks for focus (kitty): nothing", lambda: hypr("urgent", "55d0c0ff00")),
        ("Bitwarden asks for focus (ssh needs it): shown here", lambda: hypr("urgent", "55d0c0b17d")),
        ("  Hyprland: no window focused for a moment, then the workspace opens", lambda: [hypr("activewindowv2", ""), hypr("activespecial", "special:bitwarden,DP-1"), hypr("activewindowv2", "55d0c0b17d")]),
        ("Bitwarden asks again (sign after list): still shown, nothing toggled", lambda: hypr("urgent", "55d0c0b17d")),
        ("wait (you unlock and approve)", lambda: None),
        ("wait", lambda: None),
        ("you approve, then focus kitty: Bitwarden hides", lambda: hypr("activewindowv2", "55d0c0ff00")),
        ("  Hyprland: special workspace closed", lambda: hypr("activespecial", ",DP-1")),
        ("focus moves again: nothing", lambda: hypr("activewindowv2", "55d0c0ffee")),
        ("clear notifications", lambda: QMetaObject.invokeMethod(pobj, "clear")),
        ("done", lambda: app.quit()),
    ]

    def bar_window():
        for w in QGuiApplication.topLevelWindows():
            if w.metaObject().className().startswith("Bar_QMLTYPE"):
                return w
        raise RuntimeError("no bar window")

    def wheel(fx, y, delta):
        # A wheel event at fraction fx of the bar's width, y pixels from the top of the screen
        w = bar_window()
        pos = QPointF(w.width() * fx, y)
        ev = QWheelEvent(pos, pos, QPoint(0, 0), QPoint(0, delta), Qt.NoButton, Qt.NoModifier,
                         Qt.NoScrollPhase, False)
        QGuiApplication.sendEvent(w, ev)

    def wheel_on(type_name, delta):
        # A wheel event at the centre of the first item of a QML type (e.g. MediaWidget) in the bar
        w = bar_window()
        def find(item):
            if item.metaObject().className().startswith(type_name + "_QMLTYPE"):
                return item
            for child in item.childItems():
                found = find(child)
                if found is not None:
                    return found
            return None
        item = find(w.contentItem())
        if item is None:
            raise RuntimeError("no " + type_name + " in the bar")
        centre = item.mapToScene(QPointF(item.width() / 2, item.height() / 2))
        messages.append(("info", "HARNESS: %s at x=%d..%d" % (type_name, item.mapToScene(QPointF(0, 0)).x(), item.mapToScene(QPointF(item.width(), 0)).x())))
        wheel(centre.x() / w.width(), centre.y(), delta)

    def screenshot():
        path = os.environ.get("HARNESS_SCREENSHOT")
        if path:
            bar_window().grabWindow().save(path)

    def hypr(name, data):
        QMetaObject.invokeMethod(pobj, "hypr", Q_ARG("QVariant", name), Q_ARG("QVariant", data))

    def print_volume():
        messages.append(("info", "HARNESS: volume=" + str(round(pobj.property("vol"), 2))))

    def run(i=0):
        if i < len(steps):
            name, fn = steps[i]
            messages.append(("step", name))
            try:
                fn()
            except Exception as e:  # noqa
                messages.append(("PYERROR", f"{name}: {e}"))
            QTimer.singleShot(300, lambda: run(i + 1))

    QTimer.singleShot(500, run)
    app.exec()

    bad = 0
    for kind, msg in messages:
        if kind in ("step",):
            print(f"--- {msg}")
            continue
        if "HARNESS:" in msg:
            print("    ", msg)
            continue
        if kind in ("WARNING", "ERROR", "FATAL", "QML", "PYERROR"):
            bad += 1
            print(f"{kind}: {msg}")
    print(f"\n{bad} warnings/errors")
    return 0


if __name__ == "__main__":
    sys.exit(main())
