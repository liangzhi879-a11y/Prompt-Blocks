pragma Singleton
import QtQuick

QtObject {
    id: icons

    // ── Phosphor Icons (Regular) — flat · minimal · refined ──
    // Font files: assets/fonts/Phosphor-Regular.ttf
    // NOTE: registered at app startup via QFontDatabase.addApplicationFont()
    //  in promptblocks/app.py. `font.family: Icons.fontFamily` MUST be set
    //  on any Text element that renders `Icons.xxx`, otherwise Qt will use
    //  Segoe UI (which has no glyphs in the PUA range).

    // Set this when rendering pure icon characters (no regular text mixed in).
    readonly property string fontFamily: "Phosphor"

    // Set this on Text elements that mix icons + regular text.
    // Requires Qt 6.2+ (QQuickText uses char-level font fallback internally).
    readonly property var textFamilies: ["Segoe UI", "Phosphor", "Microsoft YaHei", "sans-serif"]

    // ── Navigation / Actions ──
    readonly property string accept:        "\ue182"   // check
    readonly property string cancel:        "\ue4f6"   // x
    readonly property string close:         "\ue4f6"   // x
    readonly property string minimize:      "\ue32a"   // minus
    readonly property string maximize:      "\ue45e"   // square
    readonly property string restore:       "\ue3f0"   // rectangle
    readonly property string back:          "\ue058"   // arrow-left
    readonly property string forward:       "\ue06c"   // arrow-right
    readonly property string up:            "\ue08e"   // arrow-up
    readonly property string down:          "\ue03e"   // arrow-down
    readonly property string chevronUp:     "\ue13c"   // caret-up
    readonly property string chevronDown:   "\ue136"   // caret-down
    readonly property string chevronLeft:   "\ue138"   // caret-left
    readonly property string chevronRight:  "\ue13a"   // caret-right
    readonly property string undo:          "\ue096"   // arrow-counter-clockwise
    readonly property string redo:          "\ue094"   // arrow-clockwise
    readonly property string refresh:       "\ue094"   // arrow-clockwise
    readonly property string menu:          "\ue2f0"   // list
    readonly property string more:          "\ue1fe"   // dots-three

    // ── Edit / Document ──
    readonly property string edit:          "\ue3ae"   // pencil
    readonly property string copy:          "\ue1ca"   // copy
    readonly property string paste:         "\ue196"   // clipboard
    readonly property string cut:           "\ueae0"   // scissors
    readonly property string save:          "\ue248"   // floppy-disk
    readonly property string trash:         "\ue4a6"   // trash
    readonly property string add:           "\ue3d4"   // plus
    readonly property string remove:        "\ue32a"   // minus
    readonly property string search:        "\ue30c"   // magnifying-glass
    readonly property string filter:        "\ue266"   // funnel
    readonly property string sort:          "\ue444"   // sort-ascending

    // ── Media ──
    readonly property string play:          "\ue3d0"   // play
    readonly property string stop:          "\ue46c"   // stop
    readonly property string pause:         "\ue39e"   // pause
    readonly property string previous:      "\ue42e"   // skip-back-circle
    readonly property string next:          "\ue430"   // skip-forward-circle

    // ── Status ──
    readonly property string error:         "\ue4f6"   // x
    readonly property string warning:       "\ue4e0"   // warning
    readonly property string info:          "\ue2ce"   // info
    readonly property string success:       "\ue182"   // check (alias)
    readonly property string help:          "\ue3e8"   // question
    readonly property string blocked:       "\ue3de"   // prohibit

    // ── Communication ──
    readonly property string mail:          "\ue214"   // envelope
    readonly property string chat:          "\ue15c"   // chat
    readonly property string phone:         "\ue3b8"   // phone

    // ── Objects ──
    readonly property string folder:        "\ue24a"   // folder
    readonly property string document:      "\ue230"   // file
    readonly property string fileCode:      "\ue914"   // file-code (Phosphor doesn't have this exact)
    readonly property string link:          "\ue2e2"   // link
    readonly property string pin:           "\ue3e2"   // push-pin
    readonly property string globe:         "\ue288"   // globe
    readonly property string home:          "\ue2c2"   // house
    readonly property string settings:      "\ue270"   // gear
    readonly property string shield:        "\ue40a"   // shield
    readonly property string lock:          "\ue2fa"   // lock
    readonly property string unlock:        "\ue306"   // lock-open
    readonly property string key:           "\ue2d6"   // key
    readonly property string star:          "\ue46a"   // star
    readonly property string starFilled:    "\ue46a"   // star (Phosphor Regular is outline)
    readonly property string favorite:      "\ue2a8"   // heart
    readonly property string favoriteFilled:"\ue2a8"   // heart
    readonly property string flag:          "\ue244"   // flag
    readonly property string tag:           "\ue478"   // tag

    // ── Data / Analysis ──
    readonly property string chart:         "\ue150"   // chart-bar
    readonly property string database:      "\ue1de"   // database
    readonly property string lightbulb:     "\ue2dc"   // lightbulb
    readonly property string robot:         "\ue762"   // robot
    readonly property string puzzle:        "\ue596"   // puzzle-piece
    readonly property string toolbox:       "\ueca0"   // toolbox
    readonly property string eye:           "\ue220"   // eye
    readonly property string clipboard:     "\ue196"   // clipboard
    readonly property string list:          "\ue2f0"   // list
    readonly property string bullet:        "\ue204"   // dots-three-outline (as bullet)

    // ── Import / Export ──
    readonly property string importIcon:    "\ue4be"   // upload
    readonly property string exportIcon:    "\ue20a"   // download
    readonly property string upload:        "\ue4be"   // upload
    readonly property string download:      "\ue20a"   // download
    readonly property string packageIcon:   "\ue390"   // package
    readonly property string openFile:      "\ue256"   // folder-open

    // ── AI / Magic ──
    readonly property string sparkle:       "\ue6a2"   // sparkle
    readonly property string magic:         "\ue6b6"   // magic-wand
    readonly property string optimize:      "\ue150"   // chart-bar (optimize)

    // ── User / Identity ──
    readonly property string person:        "\ue4c2"   // user
    readonly property string people:        "\ue4d6"   // users
    readonly property string contact:       "\ue4c2"   // user

    // ── Misc ──
    readonly property string hourglass:     "\ue2b2"   // hourglass
    readonly property string clock:         "\ue19a"   // clock
    readonly property string calendar:      "\ue108"   // calendar

    // ── Shapes ──
    readonly property string hexagon:       "\ue2ae"   // hexagon
    readonly property string diamond:       "\ue1ec"   // diamond
    readonly property string square:        "\ue45e"   // square
    readonly property string circleThin:    "\ue18a"   // circle
    readonly property string circleFilled:  "\ue18a"   // circle
    readonly property string triangle:      "\ue4b0"   // triangle

    // ── Extra ──
    readonly property string comment:       "\ue15c"   // chat
    readonly property string thumbsUp:      "\ue48e"   // thumbs-up
    readonly property string thumbsDown:    "\ue48c"   // thumbs-down
    readonly property string dragHandle:    "\ue208"   // dots-three-vertical
    readonly property string fullScreen:    "\ue0a2"   // arrows-out
    readonly property string variable:      "\ue862"   // brackets-angle
}
