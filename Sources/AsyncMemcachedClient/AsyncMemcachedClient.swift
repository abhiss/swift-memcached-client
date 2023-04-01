import Foundation
import NIO
import NIOExtras
import NIOConcurrencyHelpers

public struct AsyncMemcachedClient {
    private var eventLoopGroup: MultiThreadedEventLoopGroup
    private var channel: Channel?

    public init(eventLoopGroup: MultiThreadedEventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.channel = nil
    }

    public mutating func connect(host: String, port: Int, group: EventLoopGroup) async throws -> Self {
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addHandlers([IdleStateHandler(readTimeout: TimeAmount.seconds(5))])
                    .flatMap {
                        channel.pipeline.addHandlers([
                            //TODO - custom decoder that handles multiframe responses (like VA)
                            ByteToMessageHandler(LineBasedFrameDecoder()), 
                            MemcachedMetaResponseDecoder(),
                            // MessageToByteHandler(MemcachedMetaRequestEncoder()),
                            MemcachedRequestResponseHandler(),
                        ])
                    } 
                }

        let channel = try await bootstrap.connect(host: host, port: port).get()
        self.channel = channel;
        return self
    }

    public func send(command:String) async throws -> MetaResponse {
        guard let channel = self.channel else { 
            print("channel not set")
            exit(1)
        } 
        var buffOut = channel.allocator.buffer(capacity: command.count )
        buffOut.writeString(command)
        let promise: EventLoopPromise<MetaResponse> = channel.eventLoop.makePromise()

        let request = RequestWrapper(request: buffOut, promise: promise)
        channel.writeAndFlush(request, promise: nil)
        return try await request.promise.futureResult.get()
    }
}
