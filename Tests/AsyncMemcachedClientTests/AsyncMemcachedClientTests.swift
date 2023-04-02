import XCTest
import NIO

@testable import AsyncMemcachedClient

final class AsyncMemcachedClientTests: XCTestCase {

    /* MetaResponseDecoder is an inbound handler : ByteBuffer -> MetaResponse */
    func testMetaResponseDecoderHD() throws {
        // HD is a memcached's generic "success" response. No associated data.
        let channel = EmbeddedChannel(handler: MemcachedMetaResponseDecoder())
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }

        let inStr = "HD"
        var inBuffer = channel.allocator.buffer(capacity:inStr.count)
        inBuffer.writeString(inStr)

        var actual: MetaResponse? = nil;
        XCTAssertNoThrow(try channel.writeInbound(inBuffer))
        XCTAssertNoThrow(actual = try channel.readInbound(as: MetaResponse.self))
        XCTAssertEqual(actual!, .success)
    }

    func testMetaResponseDecoderEN() throws {
        // HD is a memcached's generic "success" response. No associated data.
        let channel = EmbeddedChannel(handler: MemcachedMetaResponseDecoder())
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }

        let inStr = "EN"
        var inBuffer = channel.allocator.buffer(capacity:inStr.count)
        inBuffer.writeString(inStr)

        var actual: MetaResponse? = nil;
        XCTAssertNoThrow(try channel.writeInbound(inBuffer))
        XCTAssertNoThrow(actual = try channel.readInbound(as: MetaResponse.self))
        XCTAssertEqual(actual!, .miss)
    }

    func testMetaResponseDecoderVA() throws {
        // VA is memcached's "value" response. Contains code VA, data len, and data.
        let channel = EmbeddedChannel(handler: MemcachedMetaResponseDecoder())
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
        

        var actual: MetaResponse? = nil;
        XCTAssertNoThrow(actual = try channel.readInbound(as: MetaResponse.self))
        XCTAssertEqual(actual!, .value(inBufferData))
    }

    func testMemcachedMetaRequestEncoderGet() throws {
        let channel = EmbeddedChannel(handler: MessageToByteHandler(MemcachedMetaRequestEncoder()))
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }
        let key = "key1"
        let input = MetaRequest.get(key: key)

        let expected = "mg \(key) v\r\n"
        var outBuf = channel.allocator.buffer(capacity: expected.maximumLengthOfBytes(using: .utf8))

        XCTAssertNoThrow(try channel.writeOutbound(input))
        XCTAssertNoThrow(outBuf = try channel.readOutbound(as: ByteBuffer.self)!)
        XCTAssertEqual(outBuf.readString(length: outBuf.readableBytes), expected)
    }

    func testMemcachedMetaRequestEncoderSet() throws {
        let channel = EmbeddedChannel(handler: MessageToByteHandler(MemcachedMetaRequestEncoder()))
        defer {
            let res = try! channel.finish();
            XCTAssertTrue(res.isClean)
        }
        let key = "key1"
        let data = "We do the right thing, even when it’s not easy."
        let dataLen = data.lengthOfBytes(using: .utf8);
        var  dataBuf = channel.allocator.buffer(capacity: dataLen)
        dataBuf.writeString(data)

        let input = MetaRequest.set(key:key, value: dataBuf)
        let expected = "ms \(key) \(dataLen)\r\n\(data)\r\n"
        var outBuf = channel.allocator.buffer(capacity: expected.maximumLengthOfBytes(using: .utf8))

        XCTAssertNoThrow(try channel.writeOutbound(input))
        XCTAssertNoThrow(outBuf = try channel.readOutbound(as: ByteBuffer.self)!)
        XCTAssertEqual(outBuf.readString(length: outBuf.readableBytes), expected)
    }
}
