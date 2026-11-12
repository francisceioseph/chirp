import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // As notas de voz gravam e tocam pelo núcleo (o cpal, pelo RemoteIO), que não
    // escolhe a categoria da sessão de áudio: sem esta, o iOS não deixa gravar.
    try? AVAudioSession.sharedInstance().setCategory(
      .playAndRecord, mode: .default, options: [.defaultToSpeaker])
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
