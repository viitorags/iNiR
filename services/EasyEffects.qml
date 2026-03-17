pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * Handles EasyEffects active state and presets.
 */
Singleton {
    id: root

    property bool available: false
    property bool active: false
    property bool serviceRunning: false
    property int _queuedBypassState: 0

    function fetchAvailability() {
        whichProc.running = true
    }

    function fetchActiveState() {
        if (!root.available) {
            root.serviceRunning = false
            root.active = false
            return
        }
        if (bypassStatusProc.running) return
        bypassStatusProc.running = true
    }

    function disable() {
        if (!root.available) return
        root.active = false
        root._queuedBypassState = 1
        applyBypassTimer.restart()
    }

    function enable() {
        if (!root.available) return
        root.active = true
        root._queuedBypassState = 2
        Quickshell.execDetached(["/usr/bin/bash", "-lc", "/usr/bin/easyeffects --service-mode >/dev/null 2>&1 || /usr/bin/flatpak run com.github.wwmm.easyeffects --service-mode >/dev/null 2>&1"])
        applyBypassTimer.restart()
    }

    function toggle() {
        if (root.active) {
            root.disable()
        } else {
            root.enable()
        }
    }

    function applyQueuedBypassState(): void {
        if (!root.available || bypassSetProc.running) return
        const desiredState = root._queuedBypassState
        if (desiredState !== 1 && desiredState !== 2) return
        bypassSetProc.command = ["/usr/bin/bash", "-lc",
            desiredState === 1
                ? "/usr/bin/easyeffects -b 1 >/dev/null 2>&1 || /usr/bin/flatpak run com.github.wwmm.easyeffects -b 1 >/dev/null 2>&1"
                : "/usr/bin/easyeffects -b 2 >/dev/null 2>&1 || /usr/bin/flatpak run com.github.wwmm.easyeffects -b 2 >/dev/null 2>&1"
        ]
        root._queuedBypassState = 0
        bypassSetProc.running = true
    }

    Timer {
        id: initTimer
        interval: 1200
        repeat: false
        onTriggered: {
            root.fetchAvailability()
            root.fetchActiveState()
        }
    }

    Timer {
        id: applyBypassTimer
        interval: 900
        repeat: false
        onTriggered: root.applyQueuedBypassState()
    }

    Timer {
        id: refreshStateTimer
        interval: 700
        repeat: false
        onTriggered: root.fetchActiveState()
    }

    Timer {
        id: statePollTimer
        interval: 5000
        repeat: true
        running: Config.ready && root.available
        onTriggered: root.fetchActiveState()
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                initTimer.start()
            }
        }
    }

    Process {
        id: whichProc
        running: false
        command: ["/usr/bin/which", "easyeffects"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.available = true
            } else {
                flatpakInfoProc.running = true
            }
        }
    }

    Process {
        id: flatpakInfoProc
        running: false
        command: ["/bin/sh", "-c", "flatpak info com.github.wwmm.easyeffects"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0)
        }
    }

    Process {
        id: bypassStatusProc
        running: false
        command: ["/usr/bin/bash", "-lc", "/usr/bin/easyeffects -b 3 2>/dev/null || /usr/bin/flatpak run com.github.wwmm.easyeffects -b 3 2>/dev/null"]
        stdout: StdioCollector {
            id: bypassStatusCollector
            onStreamFinished: {
                const lines = (bypassStatusCollector.text ?? "").split(/\r?\n/).map(line => line.trim()).filter(line => line.length > 0)
                const state = lines.length > 0 ? lines[lines.length - 1] : ""
                if (state === "1") {
                    root.serviceRunning = true
                    root.active = false
                } else if (state === "2") {
                    root.serviceRunning = true
                    root.active = true
                } else {
                    root.serviceRunning = false
                    root.active = false
                }
            }
        }
        onExited: (exitCode, _exitStatus) => {
            if (exitCode !== 0 && !(bypassStatusCollector.text ?? "").trim().length) {
                root.serviceRunning = false
                root.active = false
            }
        }
    }

    Process {
        id: bypassSetProc
        running: false
        command: ["/usr/bin/bash", "-lc", "/usr/bin/easyeffects -b 2 >/dev/null 2>&1 || /usr/bin/flatpak run com.github.wwmm.easyeffects -b 2 >/dev/null 2>&1"]
        onExited: (_exitCode, _exitStatus) => refreshStateTimer.restart()
    }
}
