//
//  DeviceMapView.swift
//  blist
//
//  Created by Brian Greeson on 10/19/25.
//

import MapKit
import SwiftUI

struct DeviceMapView: View {
    let device: BleDevice

    struct ColoredCell: Identifiable {
        let id = UUID()
        let coords: [CLLocationCoordinate2D]
        let color: Color
        let label: Text
    }

    private func rssiColor(_ rssi: Int) -> Color {
        // Normalize RSSI (-90 = weak, -40 = strong)
        let t = max(0, min(1, (Float(rssi) + 90) / 50))

        if t < 0.25 {
            // Very weak = black with high opacity
            let alpha = Double(0.2 + t * 2.0)
            return Color.black.opacity(alpha)
        } else if t < 0.5 {
            // Weak = green
            let localT = (t - 0.25) / 0.25
            return Color(
                red: 0.0,
                green: Double(0.5 + 0.5 * localT),
                blue: 0.0,
                opacity: 0.7
            )
        } else if t < 0.75 {
            // Medium = yellow
            let localT = (t - 0.5) / 0.25
            return Color(
                red: Double(localT),
                green: 1.0,
                blue: 0.0,
                opacity: 0.7
            )
        } else {
            // Strong = red
            let localT = (t - 0.75) / 0.25
            return Color(
                red: 1.0,
                green: Double(1.0 - localT),
                blue: 0.0,
                opacity: 0.7
            )
        }
    }

    private func buildCells(gridSizeMeters: Double = 1.0) -> [ColoredCell] {
        guard !device.locations.isEmpty else { return [] }

        // Get Bounds in MKMapPoints
        let pts = device.locations.map { MKMapPoint($0.location.coordinate) }
        var minX = pts.map(\.x).min()!
        var maxX = pts.map(\.x).max()!
        var minY = pts.map(\.y).min()!
        var maxY = pts.map(\.y).max()!

        // Padding
        let pad = gridSizeMeters * 2.0
        minX -= pad
        minY -= pad
        maxX += pad
        maxY += pad

        // Convert meters to MKMapPoints (1 pt ≈ 1 meter at equator; use MapKit helper)
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(device.locations.first!.location.coordinate.latitude)
        let step = gridSizeMeters / metersPerMapPoint

        // 2) For each cell, assign nearest reading
        var cells: [ColoredCell] = []
        var y = minY
        while y < maxY {
            var x = minX
            while x < maxX {
                let rect = MKMapRect(x: x, y: y, width: step, height: step)
                let center = MKMapPoint(x: rect.midX, y: rect.midY)

                // Find nearest
                var best: LocationWithRssi? = nil
                var bestD = Double.greatestFiniteMagnitude
                for r in device.locations {
                    let p = MKMapPoint(r.location.coordinate)
                    let d = hypot(p.x - center.x, p.y - center.y)
                    if d < bestD {
                        bestD = d
                        best = r
                    }
                }

                if let r = best {
                    // 3) Rect corners → coordinates
                    let corners = [
                        MKMapPoint(x: rect.minX, y: rect.minY),
                        MKMapPoint(x: rect.maxX, y: rect.minY),
                        MKMapPoint(x: rect.maxX, y: rect.maxY),
                        MKMapPoint(x: rect.minX, y: rect.maxY),
                    ].map { $0.coordinate }

                    cells.append(
                        ColoredCell(
                            coords: corners,
                            color: rssiColor(r.rssi).opacity(0.55),
                            label: Text("\(r.rssi)")
                        )
                    )
                }

                x += step
            }
            y += step
        }
        return cells
    }
    var body: some View {
        let cells = buildCells()
        HStack {
            Map {
                UserAnnotation()
                // Heat cells
                ForEach(cells) { cell in
                    MapPolygon(coordinates: cell.coords)
                        .foregroundStyle(cell.color)
                        .stroke(.clear)
                }
            }.mapStyle(.hybrid())
                .onChange(of: device.locations.count) { oldValue, newValue in
                    print(
                        device.locations.map {
                            "\($0.location.coordinate.latitude),\($0.location.coordinate.longitude)"
                        }
                    )
                }

        }

    }
}

#Preview {
    let adData: [String: Any] = ["kCBAdvDataLocalName": "Test Device", "kCBAdvDataIsConnectable": true]
    let locations = [
        LocationWithRssi(
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40.1650, longitude: -105.1147),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 0,
                speed: 0,
                timestamp: Date().addingTimeInterval(-1)
            ),
            rssi: -51
        ),
        LocationWithRssi(
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40.1651, longitude: -105.1147),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 0,
                speed: 0,
                timestamp: Date().addingTimeInterval(-2)
            ),
            rssi: -70
        ),
        LocationWithRssi(
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40.1651, longitude: -105.11475),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 0,
                speed: 0,
                timestamp: Date().addingTimeInterval(-3)
            ),
            rssi: -75
        ),
        LocationWithRssi(
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40.16505, longitude: -105.11477),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 0,
                speed: 0,
                timestamp: Date().addingTimeInterval(-4)
            ),
            rssi: -70
        ),
        LocationWithRssi(
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40.1650, longitude: -105.11475),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 0,
                speed: 0,
                timestamp: Date().addingTimeInterval(-5)
            ),
            rssi: -62
        ),
    ]

    let device = BleDevice(
        id: UUID(),
        name: "Test Device",
        rssi: -65,
        advertisementData: adData,
        lastUpdated: Date(),
        services: [],
        locations: locations
    )
    DeviceMapView(device: device)
}
