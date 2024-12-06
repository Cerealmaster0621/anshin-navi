<p align="center">
  <img src="Images/logo32.png" width="100" height="100" alt="AnshinNavi Logo">
</p>

<p align="center">
  <a href="https://apps.apple.com/us/app/%E5%AE%89%E5%BF%83%E3%83%8A%E3%83%93/id6738698620">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;">
  </a>
</p>

# AnshinNavi (安心ナビ)

AnshinNavi is an open source iOS application designed to help users quickly locate and navigate to nearby emergency facilities in Japan. The app provides real-time information about evacuation shelters and police stations, making it an essential tool for both residents and visitors during emergencies.

<p align="center">
  <img src="Images/bg3.png" width="1000" alt="AnshinNavi Screenshot">
</p>

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
  - Clean, modern design with focus on accessibility
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
