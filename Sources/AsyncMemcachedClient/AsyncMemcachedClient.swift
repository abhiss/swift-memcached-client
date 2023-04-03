import Foundation
import NIOCore
import NIOPosix
import NIOExtras

public struct MemcachedClient {
    private var eventLoopGroup: MultiThreadedEventLoopGroup
    private var channel: Channel?

    public init(eventLoopGroup: MultiThreadedEventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.channel = nil
    }

    public mutating func connect(host: String, port: Int) async throws -> Self {
        let bootstrap = ClientBootstrap(group: self.eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addHandlers([IdleStateHandler(readTimeout: TimeAmount.seconds(5))])
                    .flatMap {
                        channel.pipeline.addHandlers([
                            //TODO - custom ByteToMessageHandler that handles data containing "\r\n" correctly
                            ByteToMessageHandler(LineBasedFrameDecoder()), 
                            MemcachedMetaResponseDecoder(),
                            MessageToByteHandler(MemcachedMetaRequestEncoder()),
                            MemcachedRequestResponseHandler(),
                        ])
                    } 
                }
        let channel = try await bootstrap.connect(host: host, port: port).get()
        self.channel = channel;
        return self
    }

    public func execute(_ request: MetaRequest) async throws -> MetaResponse {
        guard let channel = self.channel else { 
            print("channel not set")
            exit(1)
        } 

        let promise: EventLoopPromise<MetaResponse> = channel.eventLoop.makePromise()
        let request = RequestWrapper(request: request, promise: promise)
        channel.writeAndFlush(request, promise: nil)
        return try await request.promise.futureResult.get()
    }

    public func get(_ key: String) async throws -> MetaResponse {
        let request = MetaRequest.get(key: key)
        return try await self.execute(request)
    }

    public func set(_ key: String, data: ByteBuffer) async throws -> MetaResponse {
        let request = MetaRequest.set(key: key, value: data)
        return try await self.execute(request)
    }

    public func set(_ key: String, dataStr: String) async throws -> MetaResponse {
        let dataLen = dataStr.lengthOfBytes(using: .utf8)
        var dataBuf = ByteBufferAllocator().buffer(capacity: dataLen)
        dataBuf.writeString(dataStr)

        let request = MetaRequest.set(key: key, value: dataBuf)
        return try await self.execute(request)
    }
}
