import AVKit

protocol PluginInterface {
    static var name: String! { get }
    init(config: Dictionary<String, Any>!, player: SparkPlayerInternalDelegate)
    func onViewChange(view: UIView!) -> Void
    func onPlayerItemChange(player: AVPlayer?, item: AVPlayerItem?) -> Void
    func onVideoEnded() -> Void
}
