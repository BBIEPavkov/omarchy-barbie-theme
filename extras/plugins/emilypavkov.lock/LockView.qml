import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property int lastPasswordLength: 0
  property bool celebrating: false
  property date now: new Date()
  property real lastTrailAt: 0
  property int messageIndex: 0
  // Slow drift of the whole layout so nothing stays on the same pixels.
  property real driftX: 0
  property real driftY: 0

  SequentialAnimation on driftX {
    loops: Animation.Infinite
    NumberAnimation { from: -24; to: 24; duration: 47000; easing.type: Easing.InOutSine }
    NumberAnimation { from: 24; to: -24; duration: 47000; easing.type: Easing.InOutSine }
  }

  SequentialAnimation on driftY {
    loops: Animation.Infinite
    NumberAnimation { from: -16; to: 16; duration: 31000; easing.type: Easing.InOutSine }
    NumberAnimation { from: 16; to: -16; duration: 31000; easing.type: Easing.InOutSine }
  }

  readonly property var messages: [
    "You can be anything",
    "Life in plastic, it's fantastic",
    "Dream big, sparkle always",
    "Hi Barbie! 💖",
    "Be your own kind of beautiful"
  ]

  readonly property string placeholderText: "Hi Barbie 💖"
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.3)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Color.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onFailureMessageChanged: {
    if (failureMessage.length === 0) return
    shake.restart()
    heartbreakAnim.restart()
  }
  onCelebratingChanged: {
    if (!celebrating) return
    spawnBurst(inputField.x + inputField.width / 2, inputField.y + inputField.height / 2, 60, 420)
    for (var i = 0; i < 5; i++)
      spawnBurst(Math.random() * width, Math.random() * height, 15, 160)
  }

  function spawnBurst(cx, cy, count, distance) {
    for (var i = 0; i < count; i++) {
      var angle = Math.random() * Math.PI * 2
      var dist = distance * (0.4 + Math.random() * 0.6)
      burstParticle.createObject(bursts, {
        startX: cx, startY: cy,
        endX: cx + Math.cos(angle) * dist,
        endY: cy + Math.sin(angle) * dist
      })
    }
  }

  function spawnTrail(cx, cy) {
    var t = Date.now()
    if (t - lastTrailAt < 40) return
    lastTrailAt = t
    spawnBurst(cx, cy, 1, 30)
  }

  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Bundled so the plugin works without the font installed system-wide.
  FontLoader {
    id: pacifico
    source: Qt.resolvedUrl("Pacifico-Regular.ttf")
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: "Noto Sans Symbols 2"
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "♥".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    // Hearts and sparkles drifting up behind the field.
    Item {
      id: floaties
      anchors.fill: parent
      clip: true

      Repeater {
        model: 140

        Text {
          id: floaty
          required property int index
          readonly property real drift: 20 + Math.random() * 40
          readonly property int riseMs: 9000 + Math.random() * 9000
          x: Math.random() * floaties.width
          y: floaties.height + 40
          text: ["♥", "♡", "✦", "✧"][index % 4]
          color: index % 2 === 0 ? Color.lock.borderActive : Color.lock.text
          opacity: 0.15 + Math.random() * 0.35
          font.family: "Noto Sans Symbols 2"
          font.pixelSize: 12 + Math.random() * 28
          transform: Translate { id: sway }

          SequentialAnimation on y {
            running: floaties.height > 0
            loops: Animation.Infinite
            PauseAnimation { duration: Math.random() * floaty.riseMs }
            NumberAnimation { from: floaties.height + 40; to: -60; duration: floaty.riseMs }
          }

          SequentialAnimation {
            running: true
            loops: Animation.Infinite
            NumberAnimation { target: sway; property: "x"; from: -floaty.drift; to: floaty.drift; duration: 2600; easing.type: Easing.InOutSine }
            NumberAnimation { target: sway; property: "x"; from: floaty.drift; to: -floaty.drift; duration: 2600; easing.type: Easing.InOutSine }
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: function(mouse) {
        root.wakeRequested()
        root.forcePasswordFocus()
        root.spawnBurst(mouse.x, mouse.y, 14, 120)
      }
      onPositionChanged: function(mouse) {
        root.wakeRequested()
        root.spawnTrail(mouse.x, mouse.y)
      }
    }

    Column {
      transform: Translate { x: root.driftX; y: root.driftY }
      anchors.bottom: inputField.top
      anchors.bottomMargin: 48
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 4

      Item {
        id: logo
        anchors.horizontalCenter: parent.horizontalCenter
        width: logoText.implicitWidth
        // Pacifico has a tall line box; trim the empty band below "Barbie".
        height: Math.round(logoText.implicitHeight * 0.72)
        transform: Translate { id: bob }

        SequentialAnimation {
          running: true
          loops: Animation.Infinite
          NumberAnimation { target: bob; property: "y"; from: 0; to: -10; duration: 1400; easing.type: Easing.InOutSine }
          NumberAnimation { target: bob; property: "y"; from: -10; to: 0; duration: 1400; easing.type: Easing.InOutSine }
        }

        // Outline: offset copies in a ring behind the logo (Text.Outline is only 1px).
        Repeater {
          model: 16

          Text {
            required property int index
            x: Math.cos(index / 16 * 2 * Math.PI) * 4
            y: Math.sin(index / 16 * 2 * Math.PI) * 4
            text: logoText.text
            font: logoText.font
            color: "#E0218A"
          }
        }

        Text {
          id: logoText
          text: "Barbie"
          color: Color.lock.borderActive
          font.family: pacifico.name
          font.pixelSize: Math.round(Style.font.heading * 10)
        }

        // White copy of the logo, shown only under the moving shine band.
        Text {
          id: logoShine
          anchors.fill: logoText
          text: logoText.text
          font: logoText.font
          color: "white"
          visible: false
          layer.enabled: true
        }

        Item {
          id: shineMask
          anchors.fill: parent
          visible: false
          layer.enabled: true

          Rectangle {
            id: shineBand
            width: logo.width * 0.35
            height: logo.height * 2
            y: -logo.height / 2
            x: -width * 2
            rotation: 20
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0; color: "transparent" }
              GradientStop { position: 0.5; color: "white" }
              GradientStop { position: 1; color: "transparent" }
            }

            SequentialAnimation on x {
              running: logo.width > 0
              loops: Animation.Infinite
              NumberAnimation { from: -shineBand.width * 2; to: logo.width + shineBand.width; duration: 1400; easing.type: Easing.InOutQuad }
              PauseAnimation { duration: 3500 }
            }
          }
        }

        MultiEffect {
          anchors.fill: logoText
          source: logoShine
          maskEnabled: true
          maskSource: shineMask
          maskSpreadAtMin: 1.0
          opacity: 0.85
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(root.now, "h:mm")
        color: "#E0218A"
        font.family: pacifico.name
        font.pixelSize: Math.round(Style.font.heading * 5)
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(root.now, "dddd, MMMM d")
        color: Qt.darker(Color.lock.borderActive, 1.6)
        font.family: pacifico.name
        font.pixelSize: Math.round(Style.font.heading * 2.25)
      }

      Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
      }
    }

    Text {
      id: message
      transform: Translate { x: root.driftX; y: root.driftY }
      anchors.top: inputField.bottom
      anchors.topMargin: 40
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.messages[root.messageIndex]
      color: Qt.darker(Color.lock.borderActive, 1.6)
      font.family: pacifico.name
      font.pixelSize: Math.round(Style.font.heading * 2.1)

      SequentialAnimation {
        running: true
        loops: Animation.Infinite
        PauseAnimation { duration: 5000 }
        NumberAnimation { target: message; property: "opacity"; to: 0; duration: 400 }
        ScriptAction { script: root.messageIndex = (root.messageIndex + 1) % root.messages.length }
        NumberAnimation { target: message; property: "opacity"; to: 1; duration: 400 }
      }
    }

    // Soft glow behind the pill-shaped field.
    Rectangle {
      transform: Translate { x: root.driftX; y: root.driftY }
      anchors.centerIn: inputField
      width: inputField.width + 24
      height: inputField.height + 24
      radius: height / 2
      color: root.errorState ? Color.lock.borderError : Color.lock.borderActive
      opacity: 0.25
      layer.enabled: true

      SequentialAnimation on opacity {
        running: true
        loops: Animation.Infinite
        NumberAnimation { to: 0.5; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.15; duration: 1800; easing.type: Easing.InOutSine }
      }
      layer.effect: MultiEffect {
        blurEnabled: true
        blur: 1.0
        blurMax: 32
      }
    }

    BorderSurface {
      transform: Translate { x: root.driftX; y: root.driftY }
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      anchors.centerIn: parent
      // Sits below center so the logo above clears the top edge.
      anchors.verticalCenterOffset: 50
      color: Color.lock.background
      borderSpec: root.inputBorderSpec
      radius: height / 2
      clip: true

      SequentialAnimation {
        id: shake
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 14; duration: 70 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -10; duration: 70 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 10; duration: 70 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -5; duration: 60 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
      }

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u2665"
        passwordMaskDelay: 0
        color: Color.lock.text
        selectionColor: Color.lock.selection
        selectedTextColor: Color.lock.text
        font.family: "Noto Sans Symbols 2"
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Text {
          text: "♥"
          color: Color.lock.borderActive
          font.family: "Noto Sans Symbols 2"
          font.pixelSize: Math.round(passwordInput.font.pixelSize * 0.6)
          verticalAlignment: Text.AlignVCenter
          visible: passwordInput.cursorVisible

          SequentialAnimation on opacity {
            running: passwordInput.cursorVisible
            loops: Animation.Infinite
            NumberAnimation { to: 0.2; duration: 500 }
            NumberAnimation { to: 1; duration: 500 }
          }
        }

        onTextChanged: {
          if (text.length > root.lastPasswordLength) popAnim.restart()
          root.lastPasswordLength = text.length
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      // Pops over the newest heart as it is typed.
      Text {
        id: popHeart
        readonly property real step: passwordInput.text.length > 0 ? dotMetrics.advanceWidth * root.passwordDotScale / passwordInput.text.length : 0
        x: passwordInput.x + passwordInput.cursorRectangle.x - step / 2 - passwordInput.font.letterSpacing / 2 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        text: "♥"
        color: Color.lock.borderActive
        font.family: "Noto Sans Symbols 2"
        font.pixelSize: passwordInput.font.pixelSize
        opacity: 0

        ParallelAnimation {
          id: popAnim
          NumberAnimation { target: popHeart; property: "scale"; from: 1.9; to: 1; duration: 220; easing.type: Easing.OutBack }
          NumberAnimation { target: popHeart; property: "opacity"; from: 1; to: 0; duration: 260 }
        }
      }

      Text {
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Color.lock.text : (root.failureMessage.length > 0 ? Color.lock.textError : Color.lock.placeholder)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      // Matches hyprlock, which draws its fingerprint icon in the same spot.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: Color.lock.placeholder
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    Text {
      id: heartbreak
      transform: Translate { x: root.driftX; y: root.driftY }
      anchors.left: inputField.right
      anchors.leftMargin: 16
      anchors.verticalCenter: inputField.verticalCenter
      text: "💔"
      font.family: "Noto Color Emoji"
      font.pixelSize: Math.round(root.fieldFontSize * 1.6)
      opacity: 0

      SequentialAnimation {
        id: heartbreakAnim
        ParallelAnimation {
          NumberAnimation { target: heartbreak; property: "opacity"; from: 0; to: 1; duration: 150 }
          NumberAnimation { target: heartbreak; property: "scale"; from: 0.4; to: 1.2; duration: 250; easing.type: Easing.OutBack }
        }
        PauseAnimation { duration: 900 }
        NumberAnimation { target: heartbreak; property: "opacity"; to: 0; duration: 400 }
      }
    }

    // Confetti, click bursts, and the mouse sparkle trail.
    Item {
      id: bursts
      anchors.fill: parent
    }

    Component {
      id: burstParticle

      Text {
        id: particle
        property real startX
        property real startY
        property real endX
        property real endY
        readonly property int lifeMs: 600 + Math.random() * 500
        x: startX - width / 2
        y: startY - height / 2
        text: ["♥", "♡", "✦", "✧"][Math.floor(Math.random() * 4)]
        color: Math.random() < 0.6 ? Color.lock.borderActive : Color.lock.text
        font.family: "Noto Sans Symbols 2"
        font.pixelSize: 14 + Math.random() * 22

        ParallelAnimation {
          running: true
          NumberAnimation { target: particle; property: "x"; to: particle.endX - particle.width / 2; duration: particle.lifeMs; easing.type: Easing.OutCubic }
          NumberAnimation { target: particle; property: "y"; to: particle.endY - particle.height / 2 + 40; duration: particle.lifeMs; easing.type: Easing.OutQuad }
          NumberAnimation { target: particle; property: "opacity"; from: 1; to: 0; duration: particle.lifeMs; easing.type: Easing.InQuad }
          onFinished: particle.destroy()
        }
      }
    }
  }
}
