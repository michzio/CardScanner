import UIKit

enum DeviceFeatures {
    
    static var isLandscape : Bool {
        UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height
        // or
        // UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    static var isPortrait: Bool {
        UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width
        // or
        // UIApplication.shared.statusBarOrientation.isPortrait
    }
    
    /**
     * This property tries to get 4 orientations:
     * landscapeLeft, landscapeRight, portrait, portraitUpsideDown
     * as defined by UIDeviceOrientation enum.
     * It can return also unknown orientation (which is rare case)
     */
    static var orientation: UIDeviceOrientation {
        
        // if device orientation is one of the portrait or landscape
        // return just this orinentation
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
            return deviceOrientation
        }
        
        // otherwise if there is flat (faceUp, faceDown), unknown orientation
        // try to get orientation from UIInterfaceOrientation
        // Notice that:
        // UIDeviceOrientationLandscapeRights => UIInterfaceOrientationLandscapeLeft
        // UIDeviceOrientationLandscapeLeft => UIInterfaceOrientationLandscapeRight
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        switch interfaceOrientation {
        case .landscapeLeft:
            return UIDeviceOrientation.landscapeRight
        case .landscapeRight:
            return UIDeviceOrientation.landscapeLeft
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .unknown:
            break
        @unknown default:
            break
        }
        
        // otherwise get orientation based on screen size
        if DeviceFeatures.isPortrait {
            return .portrait
        } else if DeviceFeatures.isLandscape {
            return .landscapeLeft
        }
        
        return .unknown
    }
}
