import AsyncMemcachedClient
import NIOPosix
import NIOCore

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try! group.syncShutdownGracefully()
}

var client = MemcachedClient(eventLoopGroup: group)
let connection = try await client.connect(host: "::1", port: 11211)

var writeBuf = ByteBufferAllocator().buffer(capacity: 2)
writeBuf.writeString("hi")

/// MARK: - using connection.execute with custom MetaRequest
let setRequest = MetaRequest.set(key: "greeting", value: writeBuf)
let setResponse = try await connection.execute(setRequest)
assert(setResponse == .success)

let getRequestMiss = MetaRequest.get(key:"not_greeting")
let getResponseMiss = try await connection.execute(getRequestMiss)
assert(getResponseMiss == .miss)

/// MARK: - using connection.get/set helper functions
let setResponseName = try await connection.set("name", dataStr: "Rosa")
assert(setResponseName == .success)
let getResonseName = try await connection.get("name")

// verify returned value
if case .value(value: var readBuf) = getResonseName {
    let stringResponse = readBuf.readString(length: readBuf.readableBytes)!
    assert(stringResponse == "Rosa")
    print("response: \(stringResponse)")
} else { assertionFailure("Expected to recieve value") } 
