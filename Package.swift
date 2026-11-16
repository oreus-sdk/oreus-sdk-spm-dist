// swift-tools-version:6.0
//
// Manifeste de distribution du SDK Vox Chat iOS.
//
// Publie les deux XCFrameworks précompilés (device + simulateur, minOS 18.0,
// dSYMs embarqués) sous forme de binaryTargets locaux. L'app hôte tierce
// consomme ce dépôt via SPM et importe VoxChatSDK (initialisation) ET VoxCore
// (écrans et couche de délégation hôte) : contrat d'imports duaux.
//
// Personnalisation côté client limitée à la couleur d'accent + la typographie.

import PackageDescription

let package = Package(
    name: "VoxChatSDK",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "VoxChatSDK",
            targets: ["VoxChatSDK"]
        ),
        .library(
            name: "VoxCore",
            targets: ["VoxCore"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "VoxCore",
            path: "VoxCore.xcframework"
        ),
        .binaryTarget(
            name: "VoxChatSDK",
            path: "VoxChatSDK.xcframework"
        )
    ]
)
