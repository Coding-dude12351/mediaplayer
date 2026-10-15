import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Dialogs // Required for the file picked
import QtCore

Window {
    id: root
    width: 800
    height: 600
    visible: true
    title: qsTr("Media Player")
    color: "#1c1c1c"

    // 1. Multimedia Core
    MediaPlayer {
        id: player
        audioOutput: AudioOutput { id: audio }
        videoOutput: videoOutput
    }

    // 2. File Dialog Picker
    FileDialog {
        id: fileDialog
        title: "Please choose a media file"
        currentFolder: StandardPaths.writableLocation(StandardPaths.MoviesLocation)
        nameFilters: [ "Media files (*.mp4 *.avi *.mkv *.mp3 *.wav)", "All files (*)" ]
        onAccepted: {
            player.source = fileDialog.selectedFile
            player.play()
        }
    }

    // 3. Video Display & Mouse Tracker for Auto-Hide
    VideoOutput {
        id: videoOutput
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            // Reset timer whenever mouse moves over the video
            onPositionChanged: {
                controlBar.opacity = 1.0
                hideTimer.restart()
            }
            onClicked: {
                controlBar.opacity = controlBar.opacity === 0 ? 1.0 : 0.0
            }
        }
    }

    // Timer to automatically hide controls after 3 seconds of inactivity
    Timer {
        id: hideTimer
        interval: 3000
        running: player.playbackState === MediaPlayer.PlayingState
        repeat: false
        onTriggered: {
            if (player.playbackState === MediaPlayer.PlayingState && !controlBarMouseArea.containsMouse) {
                controlBar.opacity = 0.0
            }
        }
    }

    // 4. Floating Control Bar (With Smooth Animation)
    Rectangle {
        id: controlBar
        color: "#cc2a2a2a" // Translucent dark background
        radius: 8
        height: 80
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 15
        opacity: 1.0

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        // Prevent controls from hiding while interacting with the bar
        MouseArea {
            id: controlBarMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: hideTimer.stop()
            onExited: hideTimer.restart()
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Timeline / Progress Slider
            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: formatTime(player.position)
                    color: "white"
                    font.pixelSize: 12
                }

                Slider {
                    id: progressSlider
                    width: parent.width - 100
                    from: 0
                    to: player.duration > 0 ? player.duration : 1.0
                    value: player.position
                    live: false // Only triggers position change once released

                    onMoved: {
                        player.position = value
                    }
                }

                Text {
                    text: formatTime(player.duration)
                    color: "white"
                    font.pixelSize: 12
                }
            }

            // Buttons Bar
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Button {
                    text: "Open File"
                    onClicked: fileDialog.open()
                }

                Button {
                    text: player.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState) {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }
                }

                Button {
                    text: "Stop"
                    onClicked: player.stop()
                }

                // Volume Controller
                Row {
                    spacing: 5
                    Text { text: "🔊"; color: "white" }
                    Slider {
                        width: 80
                        from: 0.0
                        to: 1.0
                        value: 0.5
                        onValueChanged: audio.volume = value
                    }
                }
            }
        }
    }

    // Helper function to format milliseconds to MM:SS format
    function formatTime(ms) {
        var totalSeconds = Math.floor(ms / 1000);
        var minutes = Math.floor(totalSeconds / 60);
        var seconds = totalSeconds % 60;
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }
}
