import PackageDescription

let package = Package(
    name: "Blackfish",
    dependencies: [
        .Package(url: "https://github.com/elliottminns/echo.git",
                majorVersion: 0),
        .Package(url: "https://github.com/elliottminns/vaquita.git",
                 Version(0, 1, 1)),
        .Package(url: "https://github.com/elliottminns/narwhal.git",
                 Version(0, 1, 0))
    ]
)
