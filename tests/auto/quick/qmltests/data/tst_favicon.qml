/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtWebEngine module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:GPL-EXCEPT$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 as published by the Free Software
** Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtTest 1.0
import QtWebEngine 1.3
import QtWebEngine.testsupport 1.0

TestWebEngineView {
    id: webEngineView
    width: 200
    height: 400

    testSupport: WebEngineTestSupport {
        property var errorPageLoadStatus: null

        function waitForErrorPageLoadSucceeded() {
            var success = _waitFor(function() { return testSupport.errorPageLoadStatus == WebEngineView.LoadSucceededStatus })
            testSupport.errorPageLoadStatus = null
            return success
        }

        errorPage.onLoadingChanged: {
            errorPageLoadStatus = loadRequest.status
        }
    }

    function removeFaviconProviderPrefix(url) {
        return url.toString().substring(16)
    }

    SignalSpy {
        id: iconChangedSpy
        target: webEngineView
        signalName: "iconChanged"
    }

    Image {
        id: favicon
        source: webEngineView.icon
    }

    TestCase {
        id: test
        name: "WebEngineFavicon"
        when: windowShown

        function init() {
            if (webEngineView.icon != '') {
                // If this is not the first test, then load a blank page without favicon, restoring the initial state.
                webEngineView.url = 'about:blank'
                verify(webEngineView.waitForLoadSucceeded())
                iconChangedSpy.wait()
            }

            iconChangedSpy.clear()
        }

        function test_faviconLoad() {
            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("favicon.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            iconChangedSpy.wait()
            compare(iconChangedSpy.count, 1)

            compare(favicon.width, 48)
            compare(favicon.height, 48)
        }

        function test_faviconLoadEncodedUrl() {
            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("favicon2.html?favicon=load should work with#whitespace!")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            iconChangedSpy.wait()
            compare(iconChangedSpy.count, 1)

            compare(favicon.width, 16)
            compare(favicon.height, 16)
        }

        function test_noFavicon() {
            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("test1.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            compare(iconChangedSpy.count, 0)

            var iconUrl = webEngineView.icon
            compare(iconUrl, Qt.resolvedUrl(""))
        }

        function test_aboutBlank() {
            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("about:blank")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            compare(iconChangedSpy.count, 0)

            var iconUrl = webEngineView.icon
            compare(iconUrl, Qt.resolvedUrl(""))
        }

        function test_unavailableFavicon() {
            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("favicon-unavailable.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            compare(iconChangedSpy.count, 0)

            var iconUrl = webEngineView.icon
            compare(iconUrl, Qt.resolvedUrl(""))
        }

        function test_errorPageEnabled() {
            skip("Error page does not work properly: QTBUG-48995")
            WebEngine.settings.errorPageEnabled = true

            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("invalid://url")
            webEngineView.url = url
            verify(webEngineView.testSupport.waitForErrorPageLoadSucceeded())

            compare(iconChangedSpy.count, 0)

            var iconUrl = webEngineView.icon
            compare(iconUrl, Qt.resolvedUrl(""))
        }

        function test_errorPageDisabled() {
            WebEngine.settings.errorPageEnabled = false

            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("invalid://url")
            webEngineView.url = url
            verify(webEngineView.waitForLoadFailed())

            compare(iconChangedSpy.count, 0)

            var iconUrl = webEngineView.icon
            compare(iconUrl, Qt.resolvedUrl(""))
        }

        function test_bestFavicon() {
            compare(iconChangedSpy.count, 0)
            var url, iconUrl

            url = Qt.resolvedUrl("favicon-misc.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            iconChangedSpy.wait()
            compare(iconChangedSpy.count, 1)

            iconUrl = removeFaviconProviderPrefix(webEngineView.icon)
            // Touch icon is ignored
            compare(iconUrl, Qt.resolvedUrl("icons/qt32.ico"))
            compare(favicon.width, 32)
            compare(favicon.height, 32)

            iconChangedSpy.clear()

            url = Qt.resolvedUrl("favicon-shortcut.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            iconChangedSpy.wait()
            verify(iconChangedSpy.count >= 1)
            iconUrl = removeFaviconProviderPrefix(webEngineView.icon)

            // If the icon URL is empty we have to wait for
            // the second iconChanged signal that propagates the expected URL
            if (iconUrl == Qt.resolvedUrl("")) {
                tryCompare(iconChangedSpy, "count", 2)
                iconUrl = removeFaviconProviderPrefix(webEngineView.icon)
            }

            compare(iconUrl, Qt.resolvedUrl("icons/qt144.png"))
            compare(favicon.width, 144)
            compare(favicon.height, 144)
        }

        function test_touchIcon() {
            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("favicon-touch.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            compare(iconChangedSpy.count, 0)

            var iconUrl = webEngineView.icon
            compare(iconUrl, Qt.resolvedUrl(""))
            compare(favicon.width, 0)
            compare(favicon.height, 0)

            WebEngine.settings.touchIconsEnabled = true

            url = Qt.resolvedUrl("favicon-touch.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            iconChangedSpy.wait()
            iconUrl = removeFaviconProviderPrefix(webEngineView.icon)
            compare(iconUrl, Qt.resolvedUrl("icons/qt144.png"))
            compare(iconChangedSpy.count, 1)
            compare(favicon.width, 144)
            compare(favicon.height, 144)
        }

        function test_multiIcon() {
            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("favicon-multi.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            iconChangedSpy.wait()
            compare(iconChangedSpy.count, 1)
            compare(favicon.width, 64)
            compare(favicon.height, 64)
        }

        function test_faviconProvider_data() {
            return [
                   { tag: "8x8", size: 8, value: 16 },
                   { tag: "16x16", size: 16, value: 16 },
                   { tag: "17x17", size: 17, value: 32 },
                   { tag: "31x31", size: 31, value: 32 },
                   { tag: "32x32", size: 32, value: 32 },
                   { tag: "33x33", size: 33, value: 64 },
                   { tag: "64x64", size: 64, value: 64 },
                   { tag: "128x128", size: 128, value: 128 },
                   { tag: "255x255", size: 255, value: 255 },
                   { tag: "256x256", size: 256, value: 255 },
            ];
        }

        function test_faviconProvider(row) {
            var faviconImage = Qt.createQmlObject("
                    import QtQuick 2.5\n
                    Image { sourceSize: Qt.size(width, height) }", test)
            var grabImage = Qt.createQmlObject("
                    import QtQuick 2.5\n
                    Image { }", test)
            var faviconCanvas = Qt.createQmlObject("
                    import QtQuick 2.5\n
                    Canvas { }", test)

            compare(iconChangedSpy.count, 0)

            var url = Qt.resolvedUrl("favicon-multi-gray.html")
            webEngineView.url = url
            verify(webEngineView.waitForLoadSucceeded())

            iconChangedSpy.wait()
            compare(iconChangedSpy.count, 1)

            faviconImage.width = row.size
            faviconImage.height = row.size
            faviconImage.source = webEngineView.icon
            verify(_waitFor(function() { return faviconImage.status == Image.Ready } ))

            faviconImage.grabToImage(function(result) {
                    grabImage.source = result.url
                })
            verify(_waitFor(function() { return grabImage.status == Image.Ready } ))

            faviconCanvas.width = faviconImage.width
            faviconCanvas.height = faviconImage.height
            var ctx = faviconCanvas.getContext("2d")
            ctx.drawImage(grabImage, 0, 0, grabImage.width, grabImage.height)

            var center = Math.round(row.size/2)
            var imageData = ctx.getImageData(center, center, center, center)
            var pixel = imageData.data

            compare(pixel[0], row.value)

            faviconImage.destroy()
            grabImage.destroy()
            faviconCanvas.destroy()
        }
    }
}