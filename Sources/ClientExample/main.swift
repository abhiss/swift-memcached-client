import AsyncMemcachedClient
import NIOPosix

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try! group.syncShutdownGracefully()
}

var client = AsyncMemcachedClient(eventLoopGroup: group)
let connection = try await client.connect(host: "::1", port: 11211, group: group)

let setResponse = try! await connection.send(command: "ms fast 2\r\nhi\r\n")
let getResponseNoValue = try! await connection.send(command: "mg fast\r\n")
let getResponseMiss = try! await connection.send(command: "mg slow\r\n")
let getResponseWithValue = try! await connection.send(command: "mg fast v\r\n")

print("setResponse: \(setResponse)")
print("getResponseNoValue: \(getResponseNoValue)")
print("getResponseMiss: \(getResponseMiss)")
if case .value(value: var inBuf) = getResponseWithValue {
    let stringResponse = inBuf.readString(length: inBuf.readableBytes)!
    print("getResponseWithValue: \(stringResponse)")
}
