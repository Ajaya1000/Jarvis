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
                ]
            ),
            buildableFolders: [
                "Jarvis/Sources",
                "Jarvis/Resources",
            ],
            dependencies: [
                .external(name: "LiteRTLM"),
                .external(name: "Textual"),
                .external(name: "ExyteChat")
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
