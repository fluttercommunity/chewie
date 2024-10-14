import UIKit
import Flutter
import GoogleCast

@main
@objc class AppDelegate: FlutterAppDelegate, GCKLoggerDelegate {
    let kReceiverAppID = kGCKDefaultMediaReceiverApplicationID
    let kDebugLoggingEnabled = true

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        GCKCastContext.setSharedInstanceWith(options)
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
        GCKLogger.sharedInstance().delegate = self
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}