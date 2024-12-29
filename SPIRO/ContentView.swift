import SwiftUI
import Charts
import CoreXLSX

struct GraphData: Identifiable {
    let id = UUID()
    let time: Double
    let volume: Double
    let flow: Double
}

struct ContentView: View {
    @State private var data: [GraphData] = []
    @State private var animatedData: [GraphData] = []

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    if animatedData.isEmpty {
                        Text("Loading data...")
                            .font(.title2)
                            .padding()
                    } else {
                        if let lastData = animatedData.last {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Flow-Volume Graph Current:")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Volume: \(lastData.volume)")
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Flow: \(lastData.flow)")
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Volume-Time Graph Current:")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Time: \(lastData.time)")
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Volume: \(lastData.volume)")
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        Text("Flow-Volume Graph")
                            .font(.title)

                        Chart(animatedData) {
                            LineMark(
                                x: .value("Volume", $0.volume),
                                y: .value("Flow", $0.flow)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                        }
                        .chartXScale(domain: 0...4)
                        .chartYScale(domain: -5...10)
                        .frame(height: 300)

                        Text("Volume-Time Graph")
                            .font(.title)

                        Chart(animatedData) {
                            LineMark(
                                x: .value("Time", $0.time),
                                y: .value("Volume", $0.volume)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                        }
                        .chartXScale(domain: 0...15000)
                        .chartYScale(domain: 0...4)
                        .frame(height: 300)
                    }
                }
                .padding()
            }
            .navigationTitle("Spirometry Graphs")
            .onAppear {
                loadExcelData {
                    animateGraphDrawing()
                }
            }
        }
    }

    func loadExcelData(completion: @escaping () -> Void) {
        guard let fileURL = Bundle.main.url(forResource: "spiro_dataset", withExtension: "xlsx") else {
            print("File not found")
            return
        }

        DispatchQueue.global(qos: .background).async {
            do {
                guard let file = XLSXFile(filepath: fileURL.path) else {
                    print("Failed to initialize XLSXFile")
                    return
                }
                guard let sheetName = try file.parseWorksheetPaths().first else {
                    print("No sheets found")
                    return
                }

                let worksheet = try file.parseWorksheet(at: sheetName)
                var parsedData: [GraphData] = []

                for row in worksheet.data?.rows.dropFirst(1) ?? [] { // Start reading from the second row
                    if let timeString = row.cells[safe: 3]?.value,
                       let volumeString = row.cells[safe: 4]?.value,
                       let flowString = row.cells[safe: 5]?.value,
                       let time = Double(timeString),
                       let volume = Double(volumeString),
                       let flow = Double(flowString) {
                        parsedData.append(GraphData(time: time, volume: volume, flow: flow))
                    }
                }

                DispatchQueue.main.async {
                    self.data = parsedData
                    completion()
                }
            } catch {
                print("Failed to parse Excel file: \(error)")
            }
        }
    }

    func animateGraphDrawing() {
        animatedData = []
        for (index, point) in data.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) { // Faster animation
                animatedData.append(point)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
