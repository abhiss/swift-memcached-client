import NIOCore

// Not a ByteToMessageDecoder because it expects "frames" separated by "\r\n".
final class MemcachedResponseDecoder: ChannelInboundHandler, Sendable {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = MemcachedResponse

    enum Expect {
        case newFrame
        case vaDataFrame(dataLen: Int)
    }
    var waitingForFrame: Expect = .newFrame
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var response = self.unwrapInboundIn(data)

        switch self.waitingForFrame {
        case .newFrame:
            if let responseCode = response.readString(length: 2) {
                let remainder = response.readString(length: response.readableBytes) ?? ""
                
                switch (responseCode) {
                case ("VA"):
                    // parse data length
                    let dataLenStr = remainder.split(separator: " ", maxSplits: 1).first
                    guard let dataLen = Int(dataLenStr ?? "") else {
                        context.fireErrorCaught(MemcachedResponseDecoderError.protocolError("VA contained invalid or no data length"))
                        return;
                    }
                    self.waitingForFrame = .vaDataFrame(dataLen: dataLen)
                case ("HD"):
                    let parsedMessage = MemcachedResponse.success
                    context.fireChannelRead(self.wrapInboundOut(parsedMessage))
                case ("EN"):
                    let parsedMessage = MemcachedResponse.miss
                    context.fireChannelRead(self.wrapInboundOut(parsedMessage))
                default:
                    context.fireChannelRead(self.wrapInboundOut(.other(responseCode+remainder)))
                }
            } else {
                context.fireErrorCaught(MemcachedResponseDecoderError.protocolError("No return code"))
            }

        case .vaDataFrame: //frame following VA response code
            self.waitingForFrame = .newFrame // done handling multi-frame VA response
            let parsedMessage = MemcachedResponse.value(response)
            context.fireChannelRead(self.wrapInboundOut(parsedMessage))
        }
    }
}

enum MemcachedResponseDecoderError: Error {
    case protocolError(String?)
}
