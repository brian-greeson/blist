//
//  DeviceListItemView.swift
//  blist
//
//  Created by Brian Greeson on 10/20/25.
//

import SwiftUI

struct DeviceListItemView: View {
    let id: UUID
    let device: BleDevice
    let isFavorite: Bool
    @Binding var selectedDevice: BleDevice?
    @Binding var showDeviceDetails: Bool
    let onRemoveFavorite: (() -> Void)?
    let onAddFavorite: (() -> Void)?

    init(
        id: UUID,
        device: BleDevice,
        isFavorite: Bool,
        selectedDevice: Binding<BleDevice?>,
        showDeviceDetails: Binding<Bool>,
        onRemoveFavorite: (() -> Void)? = nil,
        onAddFavorite: (() -> Void)? = nil
    ) {
        self.id = id
        self.device = device
        self.isFavorite = isFavorite
        self._selectedDevice = selectedDevice
        self._showDeviceDetails = showDeviceDetails
        self.onRemoveFavorite = onRemoveFavorite
        self.onAddFavorite = onAddFavorite
    }

    var body: some View {
        HStack {
            Button {
                selectedDevice = device
                showDeviceDetails = true
            } label: {
                DeviceCard(id: id, device: device)
            }
            .buttonStyle(.plain)
            .buttonStyle(.borderless)
            Button {
                if isFavorite {
                    onRemoveFavorite?()
                } else {
                    onAddFavorite?()
                }

            } label: {
                if isFavorite {
                    Image(systemName: "star.fill")
                } else {
                    Image(systemName: "star")
                }
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    let adData: [String: Any] = ["kCBAdvDataLocalName": "Test Device", "kCBAdvDataIsConnectable": true]
    let device = BleDevice(
        id: UUID(),
        name: "Test Device",
        rssi: -65,
        advertisementData: adData,
        lastUpdated: Date(),
        services: [],
        locations: []
    )
    DeviceListItemView(
        id: UUID(),
        device: device,
        isFavorite: false,
        selectedDevice: .constant(device),
        showDeviceDetails: .constant(false)
    )
}
