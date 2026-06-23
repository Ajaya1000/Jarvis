// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "Jarvis",
    dependencies: [
        .package(url: "https://github.com/google-ai-edge/LiteRT-LM", from: "0.12.0"),
        .package(url: "https://github.com/gonzalezreal/textual", from: "0.1.0"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2")
    ]
)
