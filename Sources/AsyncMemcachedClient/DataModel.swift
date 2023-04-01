import NIOCore

struct RequestWrapper {
    // TODO - let request: MetaRequest
    let request: ByteBuffer
    let promise: EventLoopPromise<MetaResponse>
}

public enum MetaRequest {
    case set(key: String, value: ByteBuffer)
    case get(key: String)
}

public enum MetaResponse: Equatable {
    case value(ByteBuffer) // VA - "value", used by metaget command when returning data
    case success // HD - generic "success" value, used by many commands
    case miss // EN - cache miss, key not found
    case other(String)
}