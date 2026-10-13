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
        assert(WindowPolicy.ripplePoint(CGPoint(x:150,y:200),primaryTop:900,target:CGRect(x:100,y:120,width:1200,height:700)) == CGPoint(x:50,y:580))
        assert(WindowPolicy.ripplePoint(CGPoint(x:-1500,y:-800),primaryTop:900,target:CGRect(x:-1600,y:900,width:1600,height:900)) == CGPoint(x:100,y:800))
        assert(WindowPolicy.ripplePoint(CGPoint(x:50,y:200),primaryTop:900,target:CGRect(x:100,y:120,width:1200,height:700)) == nil)
        assert(WindowPolicy.ripplePoint(CGPoint(x:Double.nan,y:200),primaryTop:900,target:CGRect(x:100,y:120,width:1200,height:700)) == nil)
        for target in [CGRect(x:100,y:120,width:1200,height:700), CGRect(x:-1600,y:900,width:1600,height:900),
                       CGRect(x:50,y:100,width:300,height:500), CGRect(x:50,y:100,width:699,height:500)] {
            let player = WindowPolicy.musicRect(target)
            assert(target.contains(player), "Player stays within the tracked window")
            if target.width >= 700 { assert(abs(player.midX-(target.minX+target.width*2/3))<0.001, "Player anchors in the right third") }
            assert(player.height == 44 && player.width <= 356)
            assert(target.maxY-player.maxY == (target.width < 620 ? 48 : 0), "Narrow windows leave titlebar buttons clear")
        }
        print("PASS: foreground visibility, hide/minimize policy and multi-display coordinate conversion")
    }
}
