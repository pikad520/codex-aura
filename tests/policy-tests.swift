import Foundation
import CoreGraphics
@main struct Tests {
    static func main() {
        assert(WindowPolicy.shouldShow(enabled:true, frontBundle:"com.openai.codex", hasWindow:true))
        assert(!WindowPolicy.shouldShow(enabled:true, frontBundle:"com.apple.finder", hasWindow:true))
        assert(!WindowPolicy.shouldShow(enabled:false, frontBundle:"com.openai.codex", hasWindow:true))
        assert(!WindowPolicy.shouldShow(enabled:true, frontBundle:"com.openai.codex", hasWindow:false))
        assert(WindowPolicy.appKitRect(CGRect(x:100,y:80,width:1200,height:700),primaryTop:900) == CGRect(x:100,y:120,width:1200,height:700))
        assert(WindowPolicy.appKitRect(CGRect(x:-1600,y:-900,width:1600,height:900),primaryTop:900) == CGRect(x:-1600,y:900,width:1600,height:900))
        print("PASS: foreground visibility, hide/minimize policy and multi-display coordinate conversion")
    }
}
