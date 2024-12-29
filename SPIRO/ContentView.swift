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

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    if data.isEmpty {
                        Text("Loading data...")
                            .font(.title2)
                            .padding()
                    } else {
                        if let firstData = data.first {
                            Text("Flow-Volume Graph starts at Volume: \(firstData.volume), Flow: \(firstData.flow)")
                                .font(.headline)
                                .foregroundColor(.blue)

                            Text("Volume-Time Graph starts at Time: \(firstData.time), Volume: \(firstData.volume)")
                                .font(.headline)
                                .foregroundColor(.red)
                        }

                        Text("Flow-Volume Graph")
                            .font(.title)

                        Chart(data) {
                            LineMark(
                                x: .value("Volume", $0.volume),
                                y: .value("Flow", $0.flow)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                        }
                        .frame(height: 300)

                        Text("Volume-Time Graph")
                            .font(.title)

                        Chart(data) {
                            LineMark(
                                x: .value("Time", $0.time),
                                y: .value("Volume", $0.volume)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                        }
                        .frame(height: 300)
                    }
                }
                .padding()
            }
            .navigationTitle("Spirometry Graphs")
            .onAppear(perform: loadExcelData)
        }
    }

    func loadExcelData() {
        guard let fileURL = Bundle.main.url(forResource: "spiro_dataset", withExtension: "xlsx") else {
            print("File not found")
            return
        }

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
            }
        } catch {
            print("Failed to parse Excel file: \(error)")
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
