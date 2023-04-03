import NIOCore
import Foundation

struct MemcachedRequestEncoder: MessageToByteEncoder, Sendable {
    typealias OutboundIn = MemcachedRequest

    func encode(data: MemcachedRequest, out: inout ByteBuffer) throws {
        out.reserveCapacity(20)
        switch data {
        case .get(key: let key):
            out.writeString("mg \(key) v")
        case .set(key: let key, value: var value):
            out.writeString("ms \(key) \(value.readableBytes)")
            out.writeString("\r\n")
            out.writeBuffer(&value)
        }
        out.writeString("\r\n")
    }
}
