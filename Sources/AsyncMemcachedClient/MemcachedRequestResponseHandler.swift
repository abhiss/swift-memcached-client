import NIOCore

final class MemcachedRequestResponseHandler: ChannelInboundHandler, ChannelOutboundHandler {
    typealias InboundIn = MemcachedResponse
    typealias OutboundIn = RequestWrapper
    typealias OutboundOut = MemcachedRequest

    private var queue = CircularBuffer<EventLoopPromise<MemcachedResponse>>()

    // outbound
    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let requestWrapper = self.unwrapOutboundIn(data)
        queue.append(requestWrapper.promise)
        context.write(wrapOutboundOut(requestWrapper.request), promise: promise)
    }

    // inbound
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if self.queue.isEmpty {
            context.fireChannelRead(data) // already complete
            return
        }
        let promise = queue.removeFirst()
        let response = unwrapInboundIn(data)
        promise.succeed(response)
    }
}