// swift-tools-version: 5.8

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Tagesplaner",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "Tagesplaner",
            targets: ["AppModule"],
            bundleIdentifier: "com.example.tagesplaner",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .calendar),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
