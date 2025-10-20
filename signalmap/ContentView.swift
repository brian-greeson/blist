import CoreBluetooth
import StoreKit
import SwiftData
import SwiftUI

//
//  ContentView.swift
//  blist
//
//  Created by Brian Greeson on 8/16/25.
//
enum AppView: String, CaseIterable, Codable {
    case scanView, mapView, detailView
}
struct ContentView: View {
    @StateObject private var scanner = BLEScanner()
    @StateObject private var locationManger = LocationManager()
    @StateObject private var store = StoreViewModel()
    @State private var currentView: AppView = .scanView
    @State private var selectedDevice: BleDevice?
   
    var body: some View {

        NavigationStack {
            Group {
                switch currentView {
                case .scanView:
                    ScanView(selectedDevice: $selectedDevice, scanner: scanner, store: store)
                case .mapView:
                    MapView(locationManager: locationManger)
                default:
                    ScanView(selectedDevice: $selectedDevice, scanner: scanner, store: store)
                }
            }.toolbar {
                /* ToolbarItem(placement: .topBarLeading) {
                     Button {
                         switch currentView {
                         case .scanView:
                             currentView = .mapView
                         case .mapView:
                             currentView = .scanView
                         default:
                             currentView = .scanView
                         }
                     } label: {
                         switch currentView {
                         case .scanView:
                             Image(systemName: "map")
                
                         case .mapView:
                             Image(systemName: "list.triangle")
                
                         default:
                             Image(systemName: "map")
                         }
                     }
                 }*/
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        scanner.isScanning ? scanner.stop() : scanner.start()
                    } label: {
                        Text(scanner.isScanning ? "Stop Scan" : "Start Scan")
                            .foregroundStyle(scanner.isScanning ? .red : .primary)
                        Image(
                            systemName: scanner.isScanning
                                ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
                        )
                        .foregroundStyle(scanner.isScanning ? .red : .primary)
                        .symbolEffect(
                            .variableColor.iterative.hideInactiveLayers.nonReversing,
                            options: .repeat(.continuous),
                            isActive: scanner.isScanning
                        )
                    }
                }

            }
        }.onAppear {
            locationManger.request()
            

        }
    }
}
@MainActor
final class StoreViewModel: ObservableObject {
    private let productIdentifier = "com.signalmap.app.lifetime"
    @Published var product: Product?
    @Published var isPurchased: Bool = false

    init() {
        Task {
            await loadProduct()
            await updatePurchaseStatus()
             listenForTransaction()
        }
    }

    func loadProduct() async {
        if let loaded = try? await Product.products(for: [productIdentifier]).first {
            product = loaded
        }
    }

    func purchase() async {
        guard let product else { return }
        do {
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchaseStatus()
                case .unverified(_, let verificationError):
                    // Handle unverified transaction
                    print("Unverified: \(verificationError)")
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase error: \(error)")
        }
    }
    func updatePurchaseStatus() async {
        let transactionResult = await Transaction.latest(for: productIdentifier)

        switch transactionResult {
        case .verified(let transaction):
            isPurchased = (transaction.revocationDate == nil)
        default:
            isPurchased = false
        }

    }

    private func listenForTransaction() {
        Task {
            for await update in Transaction.updates {
                switch update {
                case .verified(let transaction):
                    if transaction.productID == productIdentifier {
                        await transaction.finish()
                        await updatePurchaseStatus()
                    }
                default:
                    break
                }
            }
        }
    }
}
#Preview {
    ContentView()
}
