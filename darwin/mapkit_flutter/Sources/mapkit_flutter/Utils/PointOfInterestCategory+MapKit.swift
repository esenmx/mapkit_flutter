import MapKit

extension PlatformPointOfInterestCategory {
    /// `nil` when the category needs a newer OS than the device runs.
    var mkCategory: MKPointOfInterestCategory? {
        switch self {
        case .airport: return .airport
        case .amusementPark: return .amusementPark
        case .aquarium: return .aquarium
        case .atm: return .atm
        case .bakery: return .bakery
        case .bank: return .bank
        case .beach: return .beach
        case .brewery: return .brewery
        case .cafe: return .cafe
        case .campground: return .campground
        case .carRental: return .carRental
        case .evCharger: return .evCharger
        case .fireStation: return .fireStation
        case .fitnessCenter: return .fitnessCenter
        case .foodMarket: return .foodMarket
        case .gasStation: return .gasStation
        case .hospital: return .hospital
        case .hotel: return .hotel
        case .laundry: return .laundry
        case .library: return .library
        case .marina: return .marina
        case .movieTheater: return .movieTheater
        case .museum: return .museum
        case .nationalPark: return .nationalPark
        case .nightlife: return .nightlife
        case .park: return .park
        case .parking: return .parking
        case .pharmacy: return .pharmacy
        case .police: return .police
        case .postOffice: return .postOffice
        case .publicTransport: return .publicTransport
        case .restaurant: return .restaurant
        case .restroom: return .restroom
        case .school: return .school
        case .stadium: return .stadium
        case .store: return .store
        case .theater: return .theater
        case .university: return .university
        case .winery: return .winery
        case .zoo: return .zoo
        case .animalService:
            if #available(iOS 18.0, macOS 15.0, *) { return .animalService }
            return nil
        case .automotiveRepair:
            if #available(iOS 18.0, macOS 15.0, *) { return .automotiveRepair }
            return nil
        case .baseball:
            if #available(iOS 18.0, macOS 15.0, *) { return .baseball }
            return nil
        case .basketball:
            if #available(iOS 18.0, macOS 15.0, *) { return .basketball }
            return nil
        case .beauty:
            if #available(iOS 18.0, macOS 15.0, *) { return .beauty }
            return nil
        case .bowling:
            if #available(iOS 18.0, macOS 15.0, *) { return .bowling }
            return nil
        case .castle:
            if #available(iOS 18.0, macOS 15.0, *) { return .castle }
            return nil
        case .conventionCenter:
            if #available(iOS 18.0, macOS 15.0, *) { return .conventionCenter }
            return nil
        case .distillery:
            if #available(iOS 18.0, macOS 15.0, *) { return .distillery }
            return nil
        case .fairground:
            if #available(iOS 18.0, macOS 15.0, *) { return .fairground }
            return nil
        case .fishing:
            if #available(iOS 18.0, macOS 15.0, *) { return .fishing }
            return nil
        case .fortress:
            if #available(iOS 18.0, macOS 15.0, *) { return .fortress }
            return nil
        case .golf:
            if #available(iOS 18.0, macOS 15.0, *) { return .golf }
            return nil
        case .goKart:
            if #available(iOS 18.0, macOS 15.0, *) { return .goKart }
            return nil
        case .hiking:
            if #available(iOS 18.0, macOS 15.0, *) { return .hiking }
            return nil
        case .kayaking:
            if #available(iOS 18.0, macOS 15.0, *) { return .kayaking }
            return nil
        case .landmark:
            if #available(iOS 18.0, macOS 15.0, *) { return .landmark }
            return nil
        case .mailbox:
            if #available(iOS 18.0, macOS 15.0, *) { return .mailbox }
            return nil
        case .miniGolf:
            if #available(iOS 18.0, macOS 15.0, *) { return .miniGolf }
            return nil
        case .musicVenue:
            if #available(iOS 18.0, macOS 15.0, *) { return .musicVenue }
            return nil
        case .nationalMonument:
            if #available(iOS 18.0, macOS 15.0, *) { return .nationalMonument }
            return nil
        case .planetarium:
            if #available(iOS 18.0, macOS 15.0, *) { return .planetarium }
            return nil
        case .rockClimbing:
            if #available(iOS 18.0, macOS 15.0, *) { return .rockClimbing }
            return nil
        case .rvPark:
            if #available(iOS 18.0, macOS 15.0, *) { return .rvPark }
            return nil
        case .skatePark:
            if #available(iOS 18.0, macOS 15.0, *) { return .skatePark }
            return nil
        case .skating:
            if #available(iOS 18.0, macOS 15.0, *) { return .skating }
            return nil
        case .skiing:
            if #available(iOS 18.0, macOS 15.0, *) { return .skiing }
            return nil
        case .soccer:
            if #available(iOS 18.0, macOS 15.0, *) { return .soccer }
            return nil
        case .spa:
            if #available(iOS 18.0, macOS 15.0, *) { return .spa }
            return nil
        case .surfing:
            if #available(iOS 18.0, macOS 15.0, *) { return .surfing }
            return nil
        case .swimming:
            if #available(iOS 18.0, macOS 15.0, *) { return .swimming }
            return nil
        case .tennis:
            if #available(iOS 18.0, macOS 15.0, *) { return .tennis }
            return nil
        case .volleyball:
            if #available(iOS 18.0, macOS 15.0, *) { return .volleyball }
            return nil
        }
    }

    /// The wire case for a MapKit category; `nil` for one this package doesn't know.
    init?(mkCategory: MKPointOfInterestCategory) {
        guard let match = Self.allCases.first(where: { $0.mkCategory == mkCategory }) else { return nil }
        self = match
    }
}
