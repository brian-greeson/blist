//
//  MapView.swift
//  blist
//
//  Created by Brian Greeson on 10/12/25.
//

import SwiftUI
import MapKit


struct MapView: View {
    @ObservedObject	 var locationManager = LocationManager()
    @State private var camera: MapCameraPosition = .automatic
    @State private var hasCenteredOnUser = false
    
    var body: some View {
      
        let _ = CLLocationDistance(100);
        Map (position: $camera){
            UserAnnotation()
        }.mapControls{
            MapUserLocationButton()
            MapScaleView()
            
        }.onReceive(locationManager.$location.compactMap { $0 }) { location in
            // Only auto-center once to avoid fighting user interactions
            guard !hasCenteredOnUser else { return }
            hasCenteredOnUser = true
            
            let coordinate = location.coordinate
            // Define a span (zoom level). Smaller deltas = closer zoom.
//            let span = MKCoordinateSpan(latitudinalMeters: 10, longitudeDelta: 0.01)
           
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10, longitudinalMeters: 10)
            camera = .region(region)
        }.mapStyle(.hybrid(elevation: .realistic))
    }

}
#Preview {
    MapView(locationManager: LocationManager())
}
