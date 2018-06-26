//
//  HTTPHandler.swift
//  basic-http-endpointPackageDescription
//
//  Created by Norman Sutorius on 24.03.18.
//
import NIO
import NIOHTTP1

class HTTPHandlers: ChannelInboundHandler {
    
    //??
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    //??
    private enum State {
        case idle
        case waitingForRequestBody
        case sendingResponse
        
        mutating func requestReceived() {
            precondition(self == .idle, "Invalid state for request received: \(self)")
            self = .waitingForRequestBody
        }
        
        mutating func requestComplete() {
            precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
            self = .sendingResponse
        }
        
        mutating func responseComplete() {
            precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
            self = .idle
        }
    }
    
    private var buffer: ByteBuffer! = nil
    private var keepAlive = false
    private var state = State.idle
    
    private var infoSavedRequestHead: HTTPRequestHead?
    private var infoSavedBodyBytes: Int = 0
    
    private var continuousCount: Int = 0
    
    private var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?
    private var handlerFuture: EventLoopFuture<Void>?
    
    // MARK: basic functions of the handler
    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete()
        
        let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { ctx.close(promise: nil) }
        }
        
        ctx.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }
    // ?? 
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        if let handler = self.handler {
            handler(ctx, reqPart)
            return
        }
        
        switch reqPart {
        case .head(let request):
            if request.uri.unicodeScalars.starts(with: "/dynamic".unicodeScalars) {
//                self.handler = self.dynamicHandler(request: request)
                self.handler!(ctx, reqPart)
                return
            } else if request.uri.chopPrefix("/sendfile/") != nil {
//                self.handler = { self.handleFile(ctx: $0, request: $1, ioMethod: .sendfile, path: path) }
                self.handler!(ctx, reqPart)
                return
            } else if request.uri.chopPrefix("/fileio/") != nil {
//                self.handler = { self.handleFile(ctx: $0, request: $1, ioMethod: .nonblockingFileIO, path: path) }
                self.handler!(ctx, reqPart)
                return
            }
            
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            
            var responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.ok)
            responseHead.headers.add(name: "content-length", value: "12")
            let response = HTTPServerResponsePart.head(responseHead)
            ctx.write(self.wrapOutboundOut(response), promise: nil)
        case .body:
            break
        case .end:
            self.state.requestComplete()
            let content = HTTPServerResponsePart.body(.byteBuffer(buffer!.slice()))
            ctx.write(self.wrapOutboundOut(content), promise: nil)
            self.completeResponse(ctx, trailers: nil, promise: nil)
        }
    }
    
    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
    
    func handlerAdded(ctx: ChannelHandlerContext) {
        self.buffer = ctx.channel.allocator.buffer(capacity: 12)
        self.buffer.write(staticString: "Hello World!") // serve as default "/"
    }
    
    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        switch event {
        case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
            // The remote peer half-closed the channel. At this time, any
            // outstanding response will now get the channel closed, and
            // if we are idle or waiting for a request body to finish we
            // will close the channel immediately.
            switch self.state {
            case .idle, .waitingForRequestBody:
                ctx.close(promise: nil)
            case .sendingResponse:
                self.keepAlive = false
            }
        default:
            ctx.fireUserInboundEventTriggered(event)
        }
    }
}

// Helper Extentions
extension String {
    func chopPrefix(_ prefix: String) -> String? {
        if self.unicodeScalars.starts(with: prefix.unicodeScalars) {
            return String(self[self.index(self.startIndex, offsetBy: prefix.count)...])
        } else {
            return nil
        }
    }
    
    func containsDotDot() -> Bool {
        for idx in self.indices {
            if self[idx] == "." && idx < self.index(before: self.endIndex) && self[self.index(after: idx)] == "." {
                return true
            }
        }
        return false
    }
}
