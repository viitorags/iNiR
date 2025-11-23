pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isRecording: false

    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!checkProcess.running) {
                checkProcess.running = true
            }
        }
    }

    Process {
        id: checkProcess
        command: ["bash", "-lc", "pgrep -x wf-recorder >/dev/null && echo 1 || echo 0"]
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                const text = outputCollector.text.trim()
                root.isRecording = (text === "1")
            }
        }
    }
}
