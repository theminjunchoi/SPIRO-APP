import SwiftUI
import CoreMotion
import Charts

struct MagneticGraphView: View {
    @State private var magnetometerData: [(time: Double, x: Double, y: Double, z: Double)] = []
    @State private var frequencyData: [(time: Double, frequency: Double)] = []
    @State private var timer: Timer?
    private let motionManager = CMMotionManager()
    @State private var startTime = Date()

    var body: some View {
        VStack {
            if magnetometerData.isEmpty {
                Text("No data available")
                    .font(.title2)
                    .padding()
            } else {
                VStack {
                    Text("Frequency Data")
                        .font(.headline)

                    Chart(frequencyData, id: \.time) {
                        LineMark(
                            x: .value("Time (s)", $0.time),
                            y: .value("Frequency (Hz)", $0.frequency)
                        )
                        .foregroundStyle(.purple)
                    }
                    .chartXAxisLabel(position: .bottom) {
                        Text("Time (s)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .chartYAxisLabel(position: .leading) {
                        Text("Frequency (Hz)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(height: 200)
                    .padding()
                }

                Text("Magnetometer Data")
                    .font(.headline)

                Chart(magnetometerData, id: \.time) {
                    LineMark(
                        x: .value("Time (s)", $0.time),
                        y: .value("X Axis (µT)", $0.x)
                    )
                    .foregroundStyle(.red)

                    LineMark(
                        x: .value("Time (s)", $0.time),
                        y: .value("Y Axis (µT)", $0.y)
                    )
                    .foregroundStyle(.green)

                    LineMark(
                        x: .value("Time (s)", $0.time),
                        y: .value("Z Axis (µT)", $0.z)
                    )
                    .foregroundStyle(.blue)
                }
                .chartXAxisLabel(position: .bottom) {
                    Text("Time (s)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .chartYAxisLabel(position: .leading) {
                    Text("Magnetic Field (µT)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(height: 300)
                .padding()
            }
        }
        .navigationTitle("Magnetometer Graph")
        .onAppear {
            startTime = Date()
            startMagnetometerUpdates()
        }
        .onDisappear(perform: stopMagnetometerUpdates)
    }

    func startMagnetometerUpdates() {
        guard motionManager.isMagnetometerAvailable else {
            print("Magnetometer is not available on this device.")
            return
        }

        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.startMagnetometerUpdates(to: .main) { data, error in
            guard let data = data, error == nil else {
                print("Error reading magnetometer data: \(String(describing: error))")
                return
            }

            let elapsedTime = Date().timeIntervalSince(startTime)
            let x = data.magneticField.x
            let y = data.magneticField.y
            let z = data.magneticField.z

            magnetometerData.append((time: elapsedTime, x: x, y: y, z: z))

            // Simulate frequency data based on Z-axis (for demonstration purposes)
            let frequency = abs(z) * 0.1 // Replace this with actual frequency calculation
            frequencyData.append((time: elapsedTime, frequency: frequency))

            if magnetometerData.count > 100 {
                magnetometerData.removeFirst()
            }

            if frequencyData.count > 100 {
                frequencyData.removeFirst()
            }
        }
    }

    func stopMagnetometerUpdates() {
        motionManager.stopMagnetometerUpdates()
    }
}
