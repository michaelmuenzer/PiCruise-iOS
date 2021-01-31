import Foundation
import SwiftUI
import WebKit

struct MjpegWebView : UIViewRepresentable {
    var url: String
    
    func makeUIView(context: Context) -> WKWebView {
        guard let url = URL(string: self.url) else {
            return WKWebView()
        }
        let htmlString = "<img src=\"\(url)\" width=\"100%\" height=\"100%\" />"
        let wkWebview = WKWebView()
        wkWebview.isUserInteractionEnabled = false
        wkWebview.loadHTMLString(htmlString, baseURL: nil)
        return wkWebview
    }
    
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<MjpegWebView>) {
    }
}
