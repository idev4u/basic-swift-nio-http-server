import NIO
import NIOHTTP1


print("start the swift nio project")

let defaultHost = "127.0.0.1"
let defaultPort = 8080
let myHelloHandler = HTTPHandlers()

//enum BindTo{
//    case ip(host: String, port: Int)
//}
//
//let bindTarget: BindTo
//
//bindTarget = BindTo.ip(host: defaultHost, port: defaultPort)

// Event Loop Setup
let group = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
let threadPool  = BlockingIOThreadPool(numberOfThreads: 3)
threadPool.start()

let bootstrap = ServerBootstrap(group: group)
    // Specify backlog and enable SO_REUSEADDR for the server itself
    .serverChannelOption(ChannelOptions.backlog, value: 256)
    .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    // Set the handlers that are applied to the accepted Channels
    .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().then {
            channel.pipeline.add(handler: myHelloHandler)
        }
    }
    // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
    .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value:1)
    // ???
    .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    .childChannelOption(ChannelOptions.maxMessagesPerRead, value:1)
    .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)

///////////
defer {
    try! group.syncShutdownGracefully()
    try! threadPool.syncShutdownGracefully()
}

let channel = try { () -> Channel in
    return try bootstrap.bind(host: defaultHost, port: defaultPort).wait()
}()

print("Server started and listen on \(channel.localAddress!)")
try channel.closeFuture.wait()

print ("Server shoutdown")
