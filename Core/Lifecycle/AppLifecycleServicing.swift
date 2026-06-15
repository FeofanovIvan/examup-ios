import Foundation

protocol AppLifecycleServicing {
    func handleLaunch() async
    func handleDidEnterBackground() async
    func handleWillEnterForeground() async
}

struct DefaultAppLifecycleService: AppLifecycleServicing {
    func handleLaunch() async {}
    func handleDidEnterBackground() async {}
    func handleWillEnterForeground() async {}
}
