# The contents of this file are subject to the Common Public Attribution
# License Version 1.0 (the “License”); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://1clickBOM.com/LICENSE. The License is based on the Mozilla Public
# License Version 1.1 but Sections 14 and 15 have been added to cover use of
# software over a computer network and provide for limited attribution for the
# Original Developer. In addition, Exhibit A has been modified to be consistent
# with Exhibit B.
#
# Software distributed under the License is distributed on an
# "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations under
# the License.
#
# The Original Code is 1clickBOM.
#
# The Original Developer is the Initial Developer. The Original Developer of
# the Original Code is Kaspar Emanuel.

countries_data = get_local("/data/countries.json")
window.paste = () ->
    textarea = document.getElementById("pastebox")
    textarea.select()
    document.execCommand("paste")
    bom_manager.addToBOM(textarea.value)

get_location = (callback) ->
    url = "https://freegeoip.net/json/"
    get url, {timeout:10000}, (event) ->
        response = JSON.parse(event.target.responseText)
        browser.storageSet({country: countries_data[response.country_name]}, callback)

browser.onInstalled () ->
    get_location () ->
        browser.tabsCreate({"url": browser.getURL("html/options.html")})

window.bom_manager = new BomManager

browser.storageOnChanged (changes) ->
    if changes.country || changes.settings
        window.bom_manager = new BomManager

class TSVPageNotifier
    constructor: ->
        @onDotTSV = false
        @re = new RegExp("\.tsv$","i")
        @checkPage()
        @items   = []
        @invalid = []
        browser.tabsOnUpdated () =>
            @checkPage()
    _set_not_dotTSV: () ->
        badge.setDefault("")
        @onDotTSV = false
        @items    = []
        @invalid  = []
    checkPage: (callback) ->
        browser.tabsQuery {active:true, currentWindow:true}, (tabs) =>
            if tabs.length > 0
                tab_url = tabs[0].url.split("?")[0]
                if tabs.length >= 1 && tab_url.match(@re)
                    if /^http.?:\/\/github.com\//.test(tabs[0].url)
                        url = tab_url.replace(/blob/,"raw")
                    else if /^http.?:\/\/bitbucket.org\//.test(tabs[0].url)
                        url = tab_url.split("?")[0].replace(/src/,"raw")
                    else
                        url = tab_url
                    get url, {notify:false}, (event) =>
                        {items, invalid} = parseTSV(event.target.responseText)
                        if items.length > 0
                            badge.setDefault("\u2191", "#0000FF")
                            @onDotTSV = true
                            @items    = items
                            @invalid  = invalid
                        else
                            @_set_not_dotTSV()
                    , () =>
                        @_set_not_dotTSV()
                else
                    @_set_not_dotTSV()
                if callback?
                    callback()
            else if callback?
                callback()
    addToBOM: () ->
        @checkPage () =>
            if @onDotTSV
                window.bom_manager._add_to_bom(@items, @invalid)

window.tsvPageNotifier = new TSVPageNotifier
