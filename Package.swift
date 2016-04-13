import PackageDescription

let package = Package(
    name: "Blackfish",
    dependencies: [
        .Package(url: "https://github.com/elliottminns/echo.git",
                 majorVersion: 0, minor: 7)
    ]
)
