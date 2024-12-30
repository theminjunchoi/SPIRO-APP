import SwiftUI
import CoreMotion
import Charts

struct MagneticGraphView: View {
    @State private var magnetometerData: [(time: Double, x: Double, y: Double, z: Double)] = []
    @State private var timer: Timer?
    private let motionManager = CMMotionManager()
    private let startTime = Date()

    var body: some View {
        VStack {
            if magnetometerData.isEmpty {
                Text("No data available")
                    .font(.title2)
                    .padding()
            } else {
                Text("Magnetometer Data")
                    .font(.headline)

                Chart {
                    ForEach(magnetometerData, id: \.time) { data in
                        LineMark(
                            x: .value("Time (s)", data.time),
                            y: .value("X Axis (µT)", data.x)
                        )
                        .foregroundStyle(.red)

                        LineMark(
                            x: .value("Time (s)", data.time),
                            y: .value("Y Axis (µT)", data.y)
                        )
                        .foregroundStyle(.green)

                        LineMark(
                            x: .value("Time (s)", data.time),
                            y: .value("Z Axis (µT)", data.z)
                        )
                        .foregroundStyle(.blue)
                    }
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
        .onAppear(perform: startMagnetometerUpdates)
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

            if magnetometerData.count > 100 {
                magnetometerData.removeFirst()
            }
        }
    }

    func stopMagnetometerUpdates() {
        motionManager.stopMagnetometerUpdates()
    }
}
