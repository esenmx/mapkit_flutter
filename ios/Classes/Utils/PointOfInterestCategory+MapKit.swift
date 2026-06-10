import MapKit

extension PlatformPointOfInterestCategory {
    /// `nil` when the category needs a newer OS than the device runs
    /// (`evCharger` is iOS 18+).
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
        case .evCharger:
            if #available(iOS 18.0, *) { return .evCharger }
            return nil
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
        }
    }
}
