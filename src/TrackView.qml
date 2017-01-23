/*
 * TrackView.qml
 * Copyright (C) Damien Caliste 2014 <dcaliste@free.fr>
 *
 * TrackView.qml is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.maep.qt 1.0

Column {
    id: root

    property Track track: null
    property variant currentPlace
    property color color
    property alias lineWidth: lineWidthSlider.value
    property bool tracking: false
    property bool wptMoving: false
    property bool detailVisible: false
    property bool menu: contextMenu.parent === track_button

    signal requestDelete()
    signal requestColor(color color)
    signal requestWidth(int width)

    ListModel {
        id: waypoints
        function refresh(track, edit) {
            waypoints.clear();
            if (!track) { return }
            for (var i = 0; i < track.getWayPointLength(); i++) {
                waypoints.append({"index": i});
            }
            if (edit) { setEditable(true) }
        }
        function setEditable(value) {
            // If true, append an empty wpt to the model.
            if (value) {
                waypoints.append({"index": waypoints.count});
            } else {
                waypoints.remove(waypoints.count - 1)
            }
        }
    }
    onTrackChanged: waypoints.refresh(track, tracking)
    onTrackingChanged: waypoints.setEditable(tracking)

    width: parent.width - 2 * Theme.paddingSmall
    spacing: Theme.paddingSmall

    Formatter { id: formatter }

    Item {
        width: parent.width
        height: track_button.height
        visible: !Qt.inputMethod.visible
        ListItem {
            id: track_button
            width: parent.width
            contentHeight: Theme.itemSizeMedium
            onClicked: root.detailVisible = !root.detailVisible
            
            menu: ContextMenu {
                id: contextMenu
                Row {
                    height: Theme.itemSizeExtraSmall
                    Repeater {
                        id: colors
                        model: ["#99db431c", "#99ffff00", "#998afa72", "#9900ffff",
                                "#993828f9", "#99a328c7", "#99ffffff", "#99989898",
                                "#99000000"]
                        delegate: Rectangle {
                            width: contextMenu.width / colors.model.length
                            height: parent.height
                            color: modelData
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    contextMenu.hide()
                                    root.requestColor(color)
                                }
                            }
                        }
                    }
                }
                Slider {
                    id: lineWidthSlider
                    width: parent.width

                    minimumValue: Theme.paddingSmall / 2
                    maximumValue: Theme.paddingLarge
                    stepSize: (maximumValue - minimumValue) / 8
                    label: "track width"
                    onValueChanged: root.requestWidth(value)
                }
                MenuItem {
                    text: "clear"
                    onClicked: root.requestDelete()
                }
                MenuItem {
                    text: "save on device"
                    onClicked: pageStack.push(tracksave, { track: track })
                }
                /*MenuItem {
                    text: "export to OSM"
                    enabled: false
                }*/
            }
            PageHeader {
                id: pageHeader
                function basename(url) {
                    return url.substring(url.lastIndexOf("/") + 1)
                }
                title: (track)?(track.path.length > 0)?basename(track.path):"Unsaved track":""
                height: Theme.itemSizeMedium

                Label {
                    function duration(time) {
                        if (time < 60) {
                            return time + " s"
                        } else if (time < 3600) {
                            var m = Math.floor(time / 60)
                            return  m + " min"
                        } else {
                            var h = Math.floor(time / 3600)
                            var m = Math.floor((time - h * 3600) / 60)
                            return h + " h " + m
                        }
                    }
                    function length(lg) {
                        if (lg >= 1000) {
                            return (lg / 1000).toFixed(1) + " km"
                        } else {
                            return lg.toFixed(0) + " m"
                        }
                    }
                    parent: pageHeader.extraContent
                    anchors.bottom: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeSmall
                    text: if (track && track.duration > 0) {
                        length(track.length) + " (" + duration(track.duration) + ")"
                    } else "no accurate data"
                }
                Label {
                    function speed(length, time) {
                        if (time > 0) {
                            return (length / time * 3.6).toFixed(2) + " km/h"
                        } else {
                            return ""
                        }
                    }
                    parent: pageHeader.extraContent
                    anchors.top: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeSmall
                    text: if (track) {
                        speed(track.length, track.duration)
                    } else ""
                }
                Rectangle {
                    parent: pageHeader.extraContent
                    width: Theme.paddingSmall
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.left
                    color: root.color
                    radius: Theme.paddingSmall / 2
                }
            }
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.bottom
                opacity: root.detailVisible ? 0 : 0.7
                visible: opacity > 0 && (waypoints.count > 0 || (track && track.path.length > 0))
                source: "image://theme/icon-m-down"
                Behavior on opacity { FadeAnimation {} }
            }
        }
    }
    Label {
        function location(url, date) {
            return "in " + url.substring(0, url.lastIndexOf("/")) + " (" + formatter.formatDate(date, Formatter.TimepointRelative) + ")"
        }
        visible: root.detailVisible && !Qt.inputMethod.visible && track && track.path.length > 0
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        text: (track) ? location(track.path, new Date(track.startDate * 1000)) : ""
        horizontalAlignment: Text.AlignRight
        truncationMode: TruncationMode.Fade
        width: parent.width - Theme.paddingMedium
        anchors.right: parent.right
    }
    Item {
        visible: root.detailVisible && waypoints.count > 0
        width: parent.width
        height: wptview.height
        clip: true
        Image {
            visible: waypoints.count > 1
            source: "image://theme/icon-m-previous"
            x: - width / 2
            anchors.verticalCenter: parent.verticalCenter
            z: wptview.z + 1
        }
        SlideshowView {
            id: wptview
            width: parent.width - 2 * Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            height: Theme.itemSizeMedium
            itemWidth: width
            model: waypoints
            onCurrentIndexChanged: if (track) {
                track.highlightWayPoint(currentIndex)
                if (currentIndex < track.getWayPointLength()) {
                    map.coordinate = track.getWayPointCoord(currentIndex)
                }
            }
            onMovementEnded: wptMoving = false
            MouseArea {
                anchors.fill: parent
                z: 1000
                onPressed: { mouse.accepted = false; wptMoving = true }
            }

            delegate: TextField {
                id: textField
                property bool newWpt: tracking && (model.index == waypoints.count - 1)
                enabled: wptview.currentIndex == model.index
                opacity: enabled ? 1.0 : 0.4
                width: wptview.width
                placeholderText: newWpt ? "new waypoint description" : "waypoint " + (model.index + 1) + "has no name"
                label: newWpt ? "new waypoint at GPS position" : "name of waypoint " + (model.index + 1)
                text: (track) ? track.getWayPoint(model.index, Track.FIELD_NAME) : ""
                EnterKey.text: newWpt ? text.length > 0 ? "add" : "cancel" : "update"
                EnterKey.onClicked: {
                    if (text.length > 0 && newWpt) {
                        track.addWayPoint(currentPlace, text, "", "")
                        track.highlightWayPoint(model.index)
                        waypoints.setEditable(true)
                    }
                    map.focus = true
                }
                onTextChanged: if (!newWpt) { track.setWayPoint(model.index, Track.FIELD_NAME, text) }

                onActiveFocusChanged: wptMoving = false
            }

        }
        Image {
            visible: waypoints.count > 1
            source: "image://theme/icon-m-next"
            x: parent.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            z: wptview.z + 1
        }
    }
}
