# Getting started

Learn how to build and run the Swift Package Registry Service.

## Github Personal Access Token

Many methods of the [Github API](https://docs.github.com/en/rest?apiVersion=2022-11-28) is accessible without authentication.
However, the [rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28)
are much lower. Therefore, it is advisable to provide the service with a
[Github Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
to authenticate with the Github API.

## Building and running migrations

Check out the repo and do an initial build using the `swift` command line:

```
git clone https://github.com/CrowdStrike/swift-package-registry-service.git
cd swift-package-registry-service
swift build
```

Now let's set up the database which is used for parts of the disk cache:

```
swift run App migrate
```

You should see something like:

```
$ swift run App migrate
...
Build of product 'App' complete! (85.77s)
Migrate Command: Prepare
The following migration(s) will be prepared:
+ App.CreateRepositories on <default>
+ App.CreateManifests on <default>
+ App.CreatePackageReleases on <default>
Would you like to continue?
y/n> 
```

Type 'y' and then hit Return. Then you should see:

```
y/n> y
[ INFO ] [Migrator] Starting prepare [database-id: sqlite, migration: App.CreateRepositories]
[ INFO ] [Migrator] Finished prepare [database-id: sqlite, migration: App.CreateRepositories]
[ INFO ] [Migrator] Starting prepare [database-id: sqlite, migration: App.CreateManifests]
[ INFO ] [Migrator] Finished prepare [database-id: sqlite, migration: App.CreateManifests]
[ INFO ] [Migrator] Starting prepare [database-id: sqlite, migration: App.CreatePackageReleases]
[ INFO ] [Migrator] Finished prepare [database-id: sqlite, migration: App.CreatePackageReleases]
Migration successful
```

Now you should see a directory created called `.sprsCache` and a `db.sqlite` file inside that directory:

```
$ ls -l .sprsCache
total 88
-rw-r--r--  1 ehyche  staff  45056 Jul  1 16:48 db.sqlite
drwxr-xr-x  2 ehyche  staff     64 Jul  1 16:47 manifests
drwxr-xr-x  2 ehyche  staff     64 Jul  1 16:47 sourceArchives
```

## Running the service from the command line

Now that you have created the disk cache database, then you are now ready to run the service:

```
$ export GITHUB_API_TOKEN="<your-Github-PAT>"
$ swift run App serve
Building for debugging...
...
Build of product 'App' complete! (25.07s)
[ NOTICE ] Server started on http://127.0.0.1:8080
```

## Testing the service using curl

Before you point Swift Package Manager at this service, you might want to do some simple curl's to see it run.
All of the examples below use [this repository](https://github.com/pointfreeco/swift-clocks) as an example.

The sections below give examples of each of the 5 endpoints of the service. To make it easier, there are scripts
in the `<repo-root>/scripts` directory which take care of all of the `curl` arguments. So all of the examples
below assume you are in the `<repo-root>` directory.

### List Package Releases

```
$ ./scripts/pr-list-package-releases.sh pointfreeco swift-clocks
{
  "releases" : {
    "0.1.0" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-clocks/0.1.0"
    },
    "0.1.1" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-clocks/0.1.1"
    },
    ...,
    "1.0.5" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-clocks/1.0.5"
    },
    "1.0.6" : {
      "url" : "http://127.0.0.1:8080/pointfreeco/swift-clocks/1.0.6"
    }
  }
}
```

### Fetch release metadata

```
$ ./scripts/pr-fetch-release-metadata.sh pointfreeco swift-clocks 1.0.6
{
  "id" : "pointfreeco.swift-clocks",
  "metadata" : {
    "repositoryURLs" : [
      "https://github.com/pointfreeco/swift-clocks",
      "https://github.com/pointfreeco/swift-clocks.git",
      "git@github.com:pointfreeco/swift-clocks.git"
    ]
  },
  "publishedAt" : "2024-12-27T01:09:43Z",
  "resources" : [
    {
      "checksum" : "a7bfe45da7bdb8afd5ea2b952a3598ddb66f8874cf026b6dc6f0b15164036658",
      "name" : "source-archive",
      "type" : "application/zip"
    }
  ],
  "version" : "1.0.6"
}
```

### Fetch manifest

#### Fetching unversioned `Package.swift`

```
$ ./scripts/pr-fetch-manifest.sh pointfreeco swift-clocks 1.0.6
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "swift-clocks",
  // NB: While the `Clock` protocol is iOS 16+, etc., the package should support earlier platforms
  //     so that depending libraries and applications can conditionally use the library via
  //     availability checks.
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "Clocks",
      targets: ["Clocks"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.2.2"),
  ],
  targets: [
    .target(
      name: "Clocks",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "ClocksTests",
      dependencies: [
        "Clocks"
      ]
    ),
  ]
)

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings!.append(contentsOf: [
    .enableExperimentalFeature("StrictConcurrency")
  ])
}
```

#### Fetching Swift 6.0 manifest

```
$ ./scripts/pr-fetch-manifest.sh pointfreeco swift-clocks 1.0.6 6.0
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swift-clocks",
  // NB: While the `Clock` protocol is iOS 16+, etc., the package should support earlier platforms
  //     so that depending libraries and applications can conditionally use the library via
  //     availability checks.
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "Clocks",
      targets: ["Clocks"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.2.2"),
  ],
  targets: [
    .target(
      name: "Clocks",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "ClocksTests",
      dependencies: [
        "Clocks"
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
```

### Download Source Archive

```
$ ./scripts/pr-download-source-archive.sh pointfreeco swift-clocks 1.0.6 swift-clocks-1.0.6.zip
```

After running you should see a file called `swift-clocks-1.0.6.zip`:

```
$ ls -l swift-clocks-1.0.6.zip
-rw-r--r--  1 ehyche  staff  37893 Jul  1 20:30 swift-clocks-1.0.6.zip
```

### Lookup Package Identifiers

```
$ ./scripts/pr-lookup-identifiers.sh pointfreeco swift-clocks
{
  "identifiers" : [
    "pointfreeco.swift-clocks"
  ]
}
```

## Building and Running Using Xcode

If you want to run and debug the service using Xcode, first do the "Building and running migrations" step above, then do the following:

1. In Xcode, do File/Open and open the `Package.swift` in this repository. Allow package resolution to finish.
2. Make sure that the target build device is "My Mac".
3. Click on the `swift-package-registry-service` scheme and choose "Edit Scheme".
4. Choose the "Run" action in the left-hand pane.
5. Choose the "Arguments" tab in the top-center.
6. In the "Environment Variables" section, click the "+" button.
7. Name the new environment variable `GITHUB_API_TOKEN`.
8. Set the value of `GITHUB_API_TOKEN` to be your Github Personal Access Token.
9. Choose the "Options" tab in the top-center.
10. Select the checkbox beside "Use custom working directory" and choose the directory where you cloned the repository.
11. Choose Close in the bottom right to finish editing the `swift-package-registry-service` scheme.
12. Click the Play button in the upper-left to Build and Run.

Once the build has succeeded and the server started, you should see something like this in the Xcode console:

```
[ NOTICE ] Server started on http://127.0.0.1:8080
```

If you see a message something like this in the Xcode console:

```
[ WARNING ] No custom working directory set for this scheme, using /Users/<your-username>/Library/Developer/Xcode/DerivedData/swift-package-registry-service-github-bwqdugfplzkkyueszneqimmdhxqo/Build/Products/Debug (Vapor/DirectoryConfiguration.swift:57)
```

then you have forgotten to set the Custom Working Directory in Step 10 above.

## Changing the logging level

The Vapor log levels are:

* **Trace**: Messages that contain information normally of use only when tracing the execution of a program.
* **Debug**: Messages that contain information normally of use only when debugging a program.
* **Info**: Informational messages.
* **Notice**: Conditions that are not error conditions, but that may require special handling.
* **Warning**: Messages that are not error conditions, but more severe than Notice.
* **Error**: Error conditions.
* **Critical**: Critical error conditions that usually require immediate attention.

The default Vapor logging level is Info. If you want to change the logging level, see the
instructions below.

### Using Xcode

1. Click the `swift-package-registry-service` scheme.
2. Click Edit Scheme.
3. Click the Run action in the left pane.
4. Click the Arguments tab in the top middle.
5. Add a `--log <log-level>` argument, where `<log-level>` is `trace`, `debug`, `info`, `notice`,
   `warning`, `error`, or `critical`.

### Using swift command line

Add a `--log <log-level>` to your `swift run` command, where `<log-level>` is `trace`,
`debug`, `info`, `notice`, `warning`, `error`, or `critical`. For example, to set `debug`-level logging:

```
swift run --log debug
```
