import UIKit
import AVFoundation
class CardOverlayView: ScannerOverlayView {
    
    override var desiredHeightRatio: Double { 0.5 }
    override var desiredWidthRatio: Double { 0.6 }
    override var maxPortraitWidth: Double { 0.8 }
    override var minLandscapeHeightRatio: Double { 0.6 }
    
    override func addOverlays(_ cutout: CGRect) {
        super.addOverlays(cutout)
        // override to add additional layers on overlay
    }
}
