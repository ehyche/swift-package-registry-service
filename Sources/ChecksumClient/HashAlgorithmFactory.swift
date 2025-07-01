enum HashAlgorithmFactory {

    public static func live() -> HashAlgorithm {
        return SHA256()
    }

    public static func test(result: [UInt8]) -> HashAlgorithm {
        TestHash(result: result)
    }

    public static func mock() -> HashAlgorithm { test(result: []) }

    struct TestHash: HashAlgorithm {
        let result: [UInt8]

        public mutating func hash(_ bytes: [UInt8]) { }

        public func finalize() -> [UInt8] { result }
    }
}
