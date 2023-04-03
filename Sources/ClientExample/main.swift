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
assert(setResponseName == true)

var readBuf = try await connection.get("name")!
let stringResponse = readBuf.readString(length: readBuf.readableBytes)!
assert(stringResponse == "Rosa")
print(stringResponse)

