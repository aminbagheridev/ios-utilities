// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "FueledUtils",
	platforms: [
		.macOS(.v10_12), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
	],
	products: [
		.library(
			name: "FueledUtilsCore",
			targets: ["FueledUtilsCore"]
		),
		.library(
			name: "FueledUtilsReactiveCommon",
			targets: ["FueledUtilsReactiveCommon"]
		),
		.library(
			name: "FueledUtilsUIKit",
			targets: ["FueledUtilsUIKit"]
		),
		.library(
			name: "FueledUtilsCombine",
			targets: ["FueledUtilsCombine"]
		),
		.library(
			name: "FueledUtilsCombineOperators",
			targets: ["FueledUtilsCombineOperators"]
		),
		.library(
			name: "FueledUtilsCombineUIKit",
			targets: ["FueledUtilsCombineUIKit"]
		),
		.library(
			name: "FueledUtilsSwiftUI",
			targets: ["FueledUtilsSwiftUI"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/Quick/Quick.git", from: "4.0.0"),
		.package(url: "https://github.com/Quick/Nimble.git", from: "9.0.0"),
	],
	targets: [
		.target(
			name: "FueledUtilsCore",
			path: "FueledUtils/Core",
			linkerSettings: [
                .linkedFramework("Foundation")
            ]
		),
		.target(
			name: "FueledUtilsReactiveCommon",
			dependencies: ["FueledUtilsCore"],
			path: "FueledUtils/ReactiveCommon"
		),
		.target(
			name: "FueledUtilsUIKit",
			dependencies: ["FueledUtilsCore"],
			path: "FueledUtils/UIKit",
			linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
		),
		.target(
			name: "FueledUtilsCombine",
			dependencies: ["FueledUtilsReactiveCommon"],
			path: "FueledUtils/Combine"
		),
		.target(
			name: "FueledUtilsCombineOperators",
			dependencies: ["FueledUtilsCombine"],
			path: "FueledUtils/CombineOperators"
		),
		.target(
			name: "FueledUtilsCombineUIKit",
			dependencies: ["FueledUtilsCombine", "FueledUtilsUIKit"],
			path: "FueledUtils/CombineUIKit"
		),
		.target(
			name: "FueledUtilsSwiftUI",
			dependencies: ["FueledUtilsCombine", "FueledUtilsCore"],
			path: "FueledUtils/SwiftUI",
			linkerSettings: [
                .linkedFramework("SwiftUI", .when(platforms: [.iOS, .tvOS, .macOS])),
            ]
		),
		.testTarget(
				name: "FueledUtils",
				dependencies: [
					"FueledUtilsCombineUIKit",
					"Quick",
					"Nimble",
				],
				path: "Tests/Tests"
		),
	]
)
