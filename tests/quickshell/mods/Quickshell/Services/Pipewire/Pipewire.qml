pragma Singleton
import QtQuick
QtObject { property PwNode defaultAudioSink: PwNode {}; property PwNode defaultAudioSource: PwNode { name: "mic" } }
