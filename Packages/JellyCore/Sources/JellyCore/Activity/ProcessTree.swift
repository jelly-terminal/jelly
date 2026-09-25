public struct ProcessTree: Sendable {
    public struct Node: Equatable, Sendable {
        public var pid: Int32
        public var depth: Int

        public init(pid: Int32, depth: Int) {
            self.pid = pid
            self.depth = depth
        }
    }

    private let children: [Int32: [Int32]]
    private let known: Set<Int32>

    public init(records: some Sequence<ProcessRecord>) {
        var children: [Int32: [Int32]] = [:]
        var known: Set<Int32> = []
        for record in records {
            known.insert(record.pid)
            guard record.parent != record.pid else { continue }
            children[record.parent, default: []].append(record.pid)
        }
        self.children = children.mapValues { $0.sorted() }
        self.known = known
    }

    public func descendants(of root: Int32) -> [Node] {
        guard known.contains(root) else { return [] }
        var result: [Node] = []
        var visited: Set<Int32> = []
        var stack = [Node(pid: root, depth: 0)]
        while let node = stack.popLast() {
            guard visited.insert(node.pid).inserted else { continue }
            result.append(node)
            for child in (children[node.pid] ?? []).reversed() {
                stack.append(Node(pid: child, depth: node.depth + 1))
            }
        }
        return result
    }
}
