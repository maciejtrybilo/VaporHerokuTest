import Vapor
import Crypto
import CommonCrypto

/// Capable of generating random `Data`.
public protocol DataGenerator {
    /// Generate `count` bytes of data.
    func generateData(count: Int) throws -> Data
}
public typealias Byte = UInt8

extension Data {
    internal func cast<T>(to: T.Type = T.self) -> T {
        return withUnsafeBytes { (p: UnsafePointer<T>) in p.pointee }
    }
}

extension DataGenerator {
    /// Generates a random type `T`.
    public func generate<T>(_ type: T.Type = T.self) throws -> T {
        return try generateData(count: MemoryLayout<T>.size)
            .cast(to: T.self)
    }
}

public struct OSRandom: DataGenerator {
    /// Create a new `OSRandom`
    public init() {}
    
    /// See `DataGenerator`.
    public func generateData(count: Int) -> Data {
        var bytes = Data()
        
        for _ in 0..<count {
            let random = makeRandom(min: 0, max: .maxByte)
            bytes.append(Byte(random))
        }
        
        return bytes
    }
    
    fileprivate func makeRandom(min: Int, max: Int) -> Int {
        let top = max - min + 1
        #if os(Linux)
        // will always be initialized
        guard randomInitialized else { fatalError() }
        return Int(COperatingSystem.random() % top) + min
        #else
        return Int(arc4random_uniform(UInt32(top))) + min
        #endif
    }
}

extension Int {
    fileprivate static let maxByte: Int = Int(Byte.max)
}

#if os(Linux)
/// Generates a random number between (and inclusive of)
/// the given minimum and maximum.
private let randomInitialized: Bool = {
    /// This stylized initializer is used to work around dispatch_once
    /// not existing and still guarantee thread safety
    let current = Date().timeIntervalSinceReferenceDate
    let salt = current.truncatingRemainder(dividingBy: 1) * 100000000
    COperatingSystem.srand(UInt32(current + salt))
    return true
}()
#endif



/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    
    router.get("big") { request -> String in
        return OSRandom().generateData(count: 1_000_000).hexEncodedString()
    }
}
