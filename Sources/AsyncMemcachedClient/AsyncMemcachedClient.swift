import Foundation
import NIOCore
import NIOPosix
import NIOExtras

public struct MemcachedConnection {
    private var eventLoopGroup: MultiThreadedEventLoopGroup
    private var channel: Channel?

    public init(eventLoopGroup: MultiThreadedEventLoopGroup, host: String, port: Int) async throws {
        self.eventLoopGroup = eventLoopGroup
        self.channel = nil
        try await self.connect(host: host, port: port)
    }

    mutating func connect(host: String, port: Int) async throws {
        let bootstrap = ClientBootstrap(group: self.eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addHandlers([IdleStateHandler(readTimeout: TimeAmount.seconds(5))])
                    .flatMap {
                        channel.pipeline.addHandlers([
                            //TODO - custom ByteToMessageHandler that handles data containing "\r\n" correctly
                            ByteToMessageHandler(LineBasedFrameDecoder()), 
                            MemcachedResponseDecoder(),
                            MessageToByteHandler(MemcachedRequestEncoder()),
                            MemcachedRequestResponseHandler(),
                        ])
                    } 
                }
        let channel = try await bootstrap.connect(host: host, port: port).get()
        self.channel = channel;
    }

    public func execute(_ request: MemcachedRequest) async throws -> MemcachedResponse {
        guard let channel = self.channel else { 
            print("channel not set")
            exit(1)
        } 

        let promise: EventLoopPromise<MemcachedResponse> = channel.eventLoop.makePromise()
        let request = RequestWrapper(request: request, promise: promise)
        channel.writeAndFlush(request, promise: nil)
        return try await request.promise.futureResult.get()
    }

    public func get(_ key: String) async throws -> MemcachedResponse {
        let request = MemcachedRequest.get(key: key)
        return try await self.execute(request)
    }

    public func set(_ key: String, data: ByteBuffer) async throws -> MemcachedResponse {
        let request = MemcachedRequest.set(key: key, value: data)
        return try await self.execute(request)
    }

    public func set(_ key: String, dataStr: String) async throws -> MemcachedResponse {
        let dataLen = dataStr.lengthOfBytes(using: .utf8)
        var dataBuf = ByteBufferAllocator().buffer(capacity: dataLen)
        dataBuf.writeString(dataStr)

        let request = MemcachedRequest.set(key: key, value: dataBuf)
        return try await self.execute(request)
    }
}
