public enum MuxServer {
    public static func runIfRequested(arguments: [String] = CommandLine.arguments) {
        guard arguments.count >= 3, arguments[1] == MuxProtocol.helperArgument else { return }
        MuxHost(socketPath: arguments[2]).run()
    }
}
