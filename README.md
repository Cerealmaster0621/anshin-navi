<p align="center">
  <img src="logo32.png" width="100" height="100" alt="AnshinNavi Logo">
</p>

# AnshinNavi (安心ナビ)

AnshinNavi is an iOS application designed to help users quickly locate and navigate to nearby emergency facilities in Japan. The app provides real-time information about evacuation shelters and police stations, making it an essential tool for both residents and visitors during emergencies.

## Features

- **Real-time Location Services**: Displays your current location and nearby emergency facilities
- **Dual Facility Types**:
  - Evacuation Shelters (避難所)
  - Police Stations (交番・警察署)
- **Navigation Features**:
  - Walking directions to selected facilities
  - Estimated arrival time calculations
  - Distance information
- **User-Friendly Interface**:
  - Intuitive map interface
  - Easy facility filtering
  - Customizable display settings
- **Multilingual Support**:
  - Japanese (日本語)
  - English

## Technical Specifications

- **Platform**: iOS 16.4+
- **Framework**: SwiftUI
- **Dependencies**:
  - MapKit
  - CoreLocation
  - SwiftData
- **Architecture**: MVVM (Model-View-ViewModel)

## Privacy & Security

- Location data is used only for facility discovery and navigation
- No personal data is collected or stored
- Compliant with Apple's privacy guidelines

## Development

### Requirements

- Xcode 15.0+
- iOS 16.4+
- Swift 5.9+

### Key Components

- `MapViewModel`: Handles map interaction and location updates
- `ShelterViewModel`: Manages evacuation shelter data
- `PoliceViewModel`: Manages police station data
- `RouteViewModel`: Handles navigation calculations

## Installation

1. Clone the repository
2. Open `AnshinNavi.xcodeproj` in Xcode
3. Build and run the project

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any inquiries, please open an issue in the repository.

---

<p align="center">Made with ❤️ for safety in Japan</p>
