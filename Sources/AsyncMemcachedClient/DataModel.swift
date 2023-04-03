import NIOCore

struct RequestWrapper {
    let request: MemcachedRequest
    let promise: EventLoopPromise<MemcachedResponse>
}

public enum MemcachedRequest {
    case set(key: String, value: ByteBuffer)
    case get(key: String)
}

public enum MemcachedResponse: Equatable {
    case value(ByteBuffer) // VA - "value", used by metaget command when returning data
    case success // HD - generic "success" value, used by many commands
    case miss // EN - cache miss, key not found
    case other(String)
}