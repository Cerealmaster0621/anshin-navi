import SwiftUI
import MapKit
import CoreLocation

let SHELTERS_CSV_FILE_NAME = "全国指定緊急避難場所データ"

// MainBottonDrawer Dent weight for each sizes
let SMALL_DENT_WEIGHT = 0.1
let MEDIUM_DENT_WEIGHT = 0.4

// Padding between searchbox and MainBottonDrawer
let MAIN_DRAWER_SEARCH_BOX_PADDING:CGFloat = 14

// Maximum number of annotations to show on the map at once
let MAX_ANNOTATIONS = 200

// evacuation shelters/centers
let WHAT_IS_SHELTER_FILTER: AttributedString = {
    var text = AttributedString("""
        安心ナビで表示しているのは主に指定緊急避難場所のデータです。フィルターを有効にすることで、指定避難所としても登録されている施設が表示されます。避難所と避難場所の違いについて...
        """)
    let terms = ["指定緊急避難場所", "指定避難所"]
    for term in terms {
        var searchRange = text.startIndex..<text.endIndex
        while let range = text[searchRange].range(of: term) {
            text[range].font = .system(.footnote, design: .default, weight: .bold)
            searchRange = range.upperBound..<text.endIndex
        }
    }
    if let linkRange = text.range(of: "避難所と避難場所の違いについて...") {
        text[linkRange].foregroundColor = .blue
        text[linkRange].link = URL(string: "https://www.bousai.go.jp/taisaku/hinanbasyo.html")
    }
    
    return text
}()
