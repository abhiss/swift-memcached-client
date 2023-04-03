import XCTest
import NIO

@testable import AsyncMemcachedClient

final class AsyncMemcachedClientTests: XCTestCase {

    /* MemcachedResponseDecoder is an inbound handler : ByteBuffer -> MemcachedResponse */
    func testMemcachedResponseDecoderHD() throws {
        // HD is a memcached's generic "success" response. No associated data.
        let channel = EmbeddedChannel(handler: MemcachedResponseDecoder())
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }

        let inStr = "HD"
        var inBuffer = channel.allocator.buffer(capacity:inStr.count)
        inBuffer.writeString(inStr)

        var actual: MemcachedResponse? = nil;
        XCTAssertNoThrow(try channel.writeInbound(inBuffer))
        XCTAssertNoThrow(actual = try channel.readInbound(as: MemcachedResponse.self))
        XCTAssertEqual(actual!, .success)
    }

    func testMemcachedResponseDecoderEN() throws {
        // HD is a memcached's generic "success" response. No associated data.
        let channel = EmbeddedChannel(handler: MemcachedResponseDecoder())
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }

        let inStr = "EN"
        var inBuffer = channel.allocator.buffer(capacity:inStr.count)
        inBuffer.writeString(inStr)

        var actual: MemcachedResponse? = nil;
        XCTAssertNoThrow(try channel.writeInbound(inBuffer))
        XCTAssertNoThrow(actual = try channel.readInbound(as: MemcachedResponse.self))
        XCTAssertEqual(actual!, .miss)
    }

    func testMemcachedResponseDecoderVA() throws {
        // VA is memcached's "value" response. Contains code VA, data len, and data.
        let channel = EmbeddedChannel(handler: MemcachedResponseDecoder())
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }

        let inStrFrame1 = "VA 2"
        var inBuffer = channel.allocator.buffer(capacity:inStrFrame1.count)
        inBuffer.writeString(inStrFrame1)
        XCTAssertNoThrow(try channel.writeInbound(inBuffer))
        
        let inStrData = "hi"
        var inBufferData = channel.allocator.buffer(capacity:inStrData.count)
        inBufferData.writeString(inStrData)
        XCTAssertNoThrow(try channel.writeInbound(inBufferData))
        

        var actual: MemcachedResponse? = nil;
        XCTAssertNoThrow(actual = try channel.readInbound(as: MemcachedResponse.self))
        XCTAssertEqual(actual!, .value(inBufferData))
    }

    func testMemcachedRequestEncoderGet() throws {
        let channel = EmbeddedChannel(handler: MessageToByteHandler(MemcachedRequestEncoder()))
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }
        let key = "key1"
        let input = MemcachedRequest.get(key: key)

        let expected = "mg \(key) v\r\n"
        var outBuf = channel.allocator.buffer(capacity: expected.maximumLengthOfBytes(using: .utf8))

        XCTAssertNoThrow(try channel.writeOutbound(input))
        XCTAssertNoThrow(outBuf = try channel.readOutbound(as: ByteBuffer.self)!)
        XCTAssertEqual(outBuf.readString(length: outBuf.readableBytes), expected)
    }

    func testMemcachedRequestEncoderSet() throws {
        let channel = EmbeddedChannel(handler: MessageToByteHandler(MemcachedRequestEncoder()))
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }
        let key = "key1"
        let data = "We do the right thing, even when it’s not easy."
        let dataLen = data.lengthOfBytes(using: .utf8);
        var  dataBuf = channel.allocator.buffer(capacity: dataLen)
        dataBuf.writeString(data)

        let input = MemcachedRequest.set(key:key, value: dataBuf)
        let expected = "ms \(key) \(dataLen)\r\n\(data)\r\n"
        var outBuf = channel.allocator.buffer(capacity: expected.maximumLengthOfBytes(using: .utf8))

        XCTAssertNoThrow(try channel.writeOutbound(input))
        XCTAssertNoThrow(outBuf = try channel.readOutbound(as: ByteBuffer.self)!)
        XCTAssertEqual(outBuf.readString(length: outBuf.readableBytes), expected)
    }
}
