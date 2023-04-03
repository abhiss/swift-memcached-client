import AsyncMemcachedClient
import NIOPosix
import NIOCore

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try! group.syncShutdownGracefully()
}

var connection = try await MemcachedConnection(eventLoopGroup: group, host: "::1", port: 11211)

var writeBuf = ByteBufferAllocator().buffer(capacity: 2)
writeBuf.writeString("hi")

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
