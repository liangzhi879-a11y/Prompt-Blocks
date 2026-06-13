pragma Singleton
import QtQuick
import ".."

// Comprehensive animation library for PromptBlocks
// All durations and easing reference Theme tokens.
// Respects Theme.animReducedMotion for accessibility.

QtObject {
    id: animations

    // ── Fade In ──
    function fadeIn(target, duration, delay) {
        if (!target) return null
        duration = duration !== undefined ? duration : Theme.animNormal
        delay = delay !== undefined ? delay : 0

        if (Theme.animReducedMotion) {
            target.opacity = 1
            return null
        }

        var anim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_fadeIn"
        )
        anim.target = target
        anim.property = "opacity"
        anim.from = 0
        anim.to = 1
        anim.duration = duration
        anim.easing.type = Theme.animEasing
        anim.loops = 1
        if (delay > 0) {
            var timer = Qt.createQmlObject(
                'import QtQuick; Timer { interval: ' + delay + '; repeat: false; running: true }',
                target,
                "Animations_fadeIn_delay"
            )
            timer.triggered.connect(function() { anim.start(); timer.destroy() })
        } else {
            anim.start()
        }
        return anim
    }

    // ── Fade Out ──
    function fadeOut(target, duration) {
        if (!target) return null
        duration = duration !== undefined ? duration : Theme.animNormal

        if (Theme.animReducedMotion) {
            target.opacity = 0
            return null
        }

        var anim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_fadeOut"
        )
        anim.target = target
        anim.property = "opacity"
        anim.from = target.opacity
        anim.to = 0
        anim.duration = duration
        anim.easing.type = Theme.animEasing
        anim.loops = 1
        anim.start()
        return anim
    }

    // ── Slide In Y ──
    function slideInY(target, from, duration) {
        if (!target) return null
        from = from !== undefined ? from : 20
        duration = duration !== undefined ? duration : Theme.animNormal

        if (Theme.animReducedMotion) {
            target.opacity = 1
            return null
        }

        var originalY = target.y
        target.y = from
        target.opacity = 0

        var yAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_slideInY_y"
        )
        yAnim.target = target
        yAnim.property = "y"
        yAnim.from = from
        yAnim.to = originalY
        yAnim.duration = duration
        yAnim.easing.type = Theme.animEasing
        yAnim.loops = 1

        var opAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_slideInY_opacity"
        )
        opAnim.target = target
        opAnim.property = "opacity"
        opAnim.from = 0
        opAnim.to = 1
        opAnim.duration = duration
        opAnim.easing.type = Theme.animEasing
        opAnim.loops = 1

        yAnim.start()
        opAnim.start()
        return [yAnim, opAnim]
    }

    // ── Slide Out Y ──
    function slideOutY(target, to, duration) {
        if (!target) return null
        to = to !== undefined ? to : target.y + 20
        duration = duration !== undefined ? duration : Theme.animNormal

        if (Theme.animReducedMotion) {
            target.opacity = 0
            return null
        }

        var yAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_slideOutY_y"
        )
        yAnim.target = target
        yAnim.property = "y"
        yAnim.from = target.y
        yAnim.to = to
        yAnim.duration = duration
        yAnim.easing.type = Theme.animEasing
        yAnim.loops = 1

        var opAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_slideOutY_opacity"
        )
        opAnim.target = target
        opAnim.property = "opacity"
        opAnim.from = target.opacity
        opAnim.to = 0
        opAnim.duration = duration
        opAnim.easing.type = Theme.animEasing
        opAnim.loops = 1

        yAnim.start()
        opAnim.start()
        return [yAnim, opAnim]
    }

    // ── Scale In ──
    function scaleIn(target, duration) {
        if (!target) return null
        duration = duration !== undefined ? duration : Theme.animNormal

        if (Theme.animReducedMotion) {
            target.scale = 1
            target.opacity = 1
            return null
        }

        target.scale = 0.9
        target.opacity = 0

        var scaleAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_scaleIn_scale"
        )
        scaleAnim.target = target
        scaleAnim.property = "scale"
        scaleAnim.from = 0.9
        scaleAnim.to = 1.0
        scaleAnim.duration = duration
        scaleAnim.easing.type = Theme.animEasing
        scaleAnim.loops = 1

        var opAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_scaleIn_opacity"
        )
        opAnim.target = target
        opAnim.property = "opacity"
        opAnim.from = 0
        opAnim.to = 1
        opAnim.duration = duration
        opAnim.easing.type = Theme.animEasing
        opAnim.loops = 1

        scaleAnim.start()
        opAnim.start()
        return [scaleAnim, opAnim]
    }

    // ── Press Feedback ──
    function pressFeedback(target) {
        if (!target) return null

        if (Theme.animReducedMotion) {
            return null
        }

        var halfDuration = Theme.animFast / 2

        var downAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_press_down"
        )
        downAnim.target = target
        downAnim.property = "scale"
        downAnim.from = 1.0
        downAnim.to = 0.95
        downAnim.duration = halfDuration
        downAnim.easing.type = Easing.OutInQuad
        downAnim.loops = 1

        var upAnim = Qt.createQmlObject(
            'import QtQuick; PropertyAnimation {}',
            target,
            "Animations_press_up"
        )
        upAnim.target = target
        upAnim.property = "scale"
        upAnim.from = 0.95
        upAnim.to = 1.0
        upAnim.duration = halfDuration
        upAnim.easing.type = Easing.OutInQuad
        upAnim.loops = 1

        downAnim.finished.connect(function() { upAnim.start() })
        downAnim.start()
        return [downAnim, upAnim]
    }

    // ── Stagger List ──
    function staggerList(targets, property, endValue, staggerAmount) {
        if (!targets || targets.length === 0) return []
        staggerAmount = staggerAmount !== undefined ? staggerAmount : 50

        if (Theme.animReducedMotion) {
            for (var i = 0; i < targets.length; i++) {
                if (targets[i]) {
                    targets[i][property] = endValue
                }
            }
            return []
        }

        var anims = []
        for (var i = 0; i < targets.length; i++) {
            (function(idx) {
                var t = targets[idx]
                if (!t) return

                var delay = idx * staggerAmount

                var anim = Qt.createQmlObject(
                    'import QtQuick; PropertyAnimation {}',
                    t,
                    "Animations_stagger_" + idx
                )
                anim.target = t
                anim.property = property
                anim.to = endValue
                anim.duration = Theme.animNormal
                anim.easing.type = Theme.animEasing
                anim.loops = 1

                if (delay > 0) {
                    var timer = Qt.createQmlObject(
                        'import QtQuick; Timer { interval: ' + delay + '; repeat: false; running: true }',
                        t,
                        "Animations_stagger_delay_" + idx
                    )
                    timer.triggered.connect(function() { anim.start(); timer.destroy() })
                } else {
                    anim.start()
                }
                anims.push(anim)
            })(i)
        }
        return anims
    }
}
