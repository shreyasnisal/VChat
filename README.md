# VChat
This repostory contains the VChat application, a messaging app for Android and iOS devices, developed in Flutter.

## Getting Started

These instructions will get you a copy of the project up and running on your local system for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Flutter

### Installing

Run `flutter packages get` to install the required dependencies.

## Deployment

In the project root directory, run `flutter run` to build and run the project on an emulator or a connected device.

Note: To build the project on an android device, you must have android SDK installed and 'adb' added to your PATH system variable.

Note: To build the project on an iOS device, you require the machine running the macOS, and XCode installed.

### Building an apk File

To build an unsigned apk file for the application, use the command `flutter build -v apk` from the project root directory. The generated apk would be located in <project-root>/build/app/outputs/apk/release.

To generate a signed apk, you would need to generate a keystore file.

## Contributing

Issues are welcome. Please add a screenshot of bug and code snippet. Quickest way to solve issue is to reproduce it on one of the examples.

Pull requests are welcome. If you want to make major changes, it is better to first create an issue and discuss it first.


