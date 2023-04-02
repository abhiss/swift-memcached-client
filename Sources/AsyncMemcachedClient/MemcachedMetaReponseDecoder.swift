import NIOCore

// Not a ByteToMessageDecoder because it expects "frames" separated by "\r\n".
final class MemcachedMetaResponseDecoder: ChannelInboundHandler, Sendable {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = MetaResponse

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
                        context.fireErrorCaught(MemcachedMetaResponseDecoderError.protocolError("VA contained invalid or no data length"))
                        return;
                    }
                    self.waitingForFrame = .vaDataFrame(dataLen: dataLen)
                case ("HD"):
                    let parsedMessage = MetaResponse.success
                    context.fireChannelRead(self.wrapInboundOut(parsedMessage))
                case ("EN"):
                    let parsedMessage = MetaResponse.miss
                    context.fireChannelRead(self.wrapInboundOut(parsedMessage))
                default:
                    context.fireChannelRead(self.wrapInboundOut(.other(responseCode+remainder)))
                }
            } else {
                context.fireErrorCaught(MemcachedMetaResponseDecoderError.protocolError("No return code"))
            }

        case .vaDataFrame: //frame following VA response code
            self.waitingForFrame = .newFrame // done handling multi-frame VA response
            let parsedMessage = MetaResponse.value(response)
            context.fireChannelRead(self.wrapInboundOut(parsedMessage))
        }
    }
}

enum MemcachedMetaResponseDecoderError: Error {
    case protocolError(String?)
}
