/// This is a protocol for computing a SHA256 hash by providing one buffer at a time
/// instead of providing the whole buffer up front.

import Crypto

public protocol HashAlgorithm: Sendable {

    /// Hashes the input bytes
    mutating func hash(_ bytes: [UInt8])

    /// Returns the hash
    func finalize() -> [UInt8]
}

struct SHA256: HashAlgorithm, @unchecked Sendable {
    private var sha256 = Crypto.SHA256()

    public init() { }

    mutating func hash(_ bytes: [UInt8]) {
        sha256.update(data: bytes)
    }

    func finalize() -> [UInt8] {
        let digest = sha256.finalize()
        var output = [UInt8]()
        digest.withUnsafeBytes { buffer in
            output.append(contentsOf: buffer)
        }
        return output
    }
}
