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
}
