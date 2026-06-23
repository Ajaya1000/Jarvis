import ProjectDescription

let project = Project(
    name: "Jarvis",
    targets: [
        .target(
            name: "Jarvis",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.Jarvis",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSLocationWhenInUseUsageDescription": "Jarvis needs access to your location to provide weather and location-based information.",
                    "NSLocationAlwaysAndWhenInUseUsageDescription": "Jarvis needs access to your location to provide weather and location-based information.",
                    "NSMicrophoneUsageDescription": "Jarvis needs microphone access to record audio messages.",
                    "NSPhotoLibraryUsageDescription": "Jarvis needs photo library access so you can send images to your AI agent.",
                ]
            ),
            buildableFolders: [
                "Jarvis/Sources",
                "Jarvis/Resources",
            ],
            dependencies: [
                .external(name: "LiteRTLM"),
                .external(name: "Textual"),
                .external(name: "MarkdownUI")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "Q4Y732FL55"
                ]
            )
        ),
        .target(
            name: "JarvisTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.JarvisTests",
            infoPlist: .default,
            buildableFolders: [
                "Jarvis/Tests"
            ],
            dependencies: [.target(name: "Jarvis")]
        ),
    ]
)
