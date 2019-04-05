![Natrium](Assets/logo.png)

Natrium is part of the **[E-sites iOS Suite](https://github.com/e-sites/iOS-Suite)**.

---

A pre-build (Swift) script to alter your Xcode project at build-time per environment and build configuration.

[![forthebadge](http://forthebadge.com/images/badges/made-with-swift.svg)](http://forthebadge.com) [![forthebadge](http://forthebadge.com/images/badges/built-with-swag.svg)](http://forthebadge.com)

[![Platform](https://img.shields.io/cocoapods/p/Natrium.svg?style=flat)](https://cocoapods.org/pods/Natrium)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Natrium.svg)](https://cocoapods.org/pods/Natrium)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Travis-ci](https://travis-ci.org/e-sites/Natrium.svg?branch=master&001)](https://travis-ci.org/e-sites/Natrium)

# TL;DR

With Natrium you can change this:

```swift
#if ENVIRONMENT_STAGING
    let apiHost = "mynice.staging-api.com"
    
#elseif ENVIRONMENT_DEVELOPMENT
    let apiHost = "mynice.dev-api.com"
    
#else
    let apiHost = "mynice.api.com"
#endif

Alamofire.request("https://\(apiHost)/items").responseJSON { response in
    // ...
}
```
![Build configurations jungle](Assets/build-configurations.png)

Into this:

```swift
let apiHost = Natrium.Config.apiHost

Alamofire.request("https://\(apiHost)/items").responseJSON { response in
    // ...
}
```
![Build configurations jungle](Assets/build-configurations-natrium.png)

### 🧙‍♂️ With the magic of pre-action run scripts. 😱

# Migration

### To v7.x
- `natrium install` is removed
- Both `.natrium-env` and `.env` files can be used for environment variables
- CLI no longer needs `--project` argument
- No longer supports Objective-c, use v6.4.0 if you still need it.

### To v6.x 
For Natrium v6.x you need to manually import the `Natrium.swift` file to your project to make it work in the new xcode build system. Read the [Installation](#installation) guide.

### From v5.x
Natrium v5.x doesn't need a build phase script anymore.    
Open your `Build Phases` from your target settings and remove the `[Natrium] check` step.    
    
Else your build will fail during the script steps

# Roadmap
- [x] Swift 4.2 compatible
- [x] Use swift instead of ruby
- [x] Remove ImageMagick dependency
- [x] Unit tests
- [x] Different installation options (apart from CocoaPods)
- [x] Better error handling / reporting

# Installation

- CocoaPods → [Read the instructions here](docs/INSTALL_COCOAPODS.md).
- Carthage → [Read the instructions here](docs/INSTALL_CARTHAGE.md).
- Manually → [Read the instructions here](docs/INSTALL_MANUALLY.md).

# Implementation

## Swift
Just add `Natrium.swift` (from the designated location, see installation guide) to your project's target (do not copy).

# Configuration

Configuration documentation can be found [here](docs/CONFIGURATION.md).

# Usage

The example `.natrium.yml` as shown above, will result in the following Config.swift file:

```swift
import Foundation

/// Natrium.swift
/// Autogenerated by natrium
///
/// - see: https://github.com/e-sites/Natrium

enum Natrium {

    enum Environment: String {
        case staging = "Staging"
        case production = "Production"
    }

    enum Configuration: String {
        case debug = "Debug"
        case release = "Release"
        case adhoc = "Adhoc"
    }

    enum Config {
        static let environment: Natrium.Environment = .staging
        static let configuration: Natrium.Configuration = .debug
        static let testVariableDouble: Double = 1.0
        static let testVariableString: String = "debugString"
        static let testVariableBoolean: Bool = false
        static let testVariableInteger: Int = 125
    }
}
```

It can be used like so:

```swift
class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        print("bundle identifier: \(Bundle.main.bundleIdentifier!)")
        print("environment: \(Natrium.Config.environment)")
    }
}
```

**Result:**

```
bundle identifier: com.esites.app.staging
environment: Staging
```

# Development

Run
 
```
swift package generate-xcodeproj
```

and open `Natrium.xcodeproj`


# Advanced


## Logging

In the `Pods/Natrium/bin/` folder you can find `natrium.log` with the logs of the previous build. It might help you with debugging.

## Environment variables

If you place `.env` in the root of your project. Natrium will use that fill to add environment variables to your already existing environment variables.
The `.env` file should have to following format:

```
KEY=VALUE
```

for instance:

```
PRODUCTION_SECRET_API_TOKEN=3489uierhjkfbnvcx
STAGING_SECRET_API_TOKEN=iujk9qijs41
```

This way you can use `#env(PRODUCTION_SECRET_API_TOKEN)` in your `.natrium.yml` file.

For CI/CD pipelines you can simply add those environment variables to your build pipeline (in travis or buddybuild for instance).

But if you want to use it for local (debug) builds, this file can be helpful.   
⚠️ Don't forget to add `.env` to your `.gitignore`