import SwiftUI
import Charts
import CoreXLSX

struct ExcelGraphData: Identifiable {
    let id = UUID()
    let time: Double
    let volume: Double
    let flow: Double
}

struct ExcelGraphView: View {
    @State private var data: [ExcelGraphData] = []
    @State private var animatedData: [ExcelGraphData] = []
    @State private var fvcValue: Double? = nil
    @State private var fev1Value: Double? = nil

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 20) {
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
                            Text("Volume: \(lastData.volume)")
                                .font(.body)
                            Text("Flow: \(lastData.flow)")
                                .font(.body)

                            Text("Volume-Time Graph Current:")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text("Time: \(lastData.time)")
                                .font(.body)
                            Text("Volume: \(lastData.volume)")
                                .font(.body)
                        }
                    }

                    if let fvc = fvcValue {
                        Text("FVC Value: \(String(format: "%.2f", fvc)) L")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let fev1 = fev1Value {
                        Text("FEV1 Value: \(String(format: "%.2f", fev1)) L")
                            .font(.title3)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .chartXAxisLabel("Volume")
                    .chartYAxisLabel("Flow")
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
                    .chartXAxisLabel("Time")
                    .chartYAxisLabel("Volume")
                    .frame(height: 300)
                }
            }
            .padding()
        }
        .onAppear {
            loadExcelData {
                calculateFVCandFEV1()
                animateGraphDrawing()
            }
        }
        .navigationTitle("Spirometry Graphs")
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
                var parsedData: [ExcelGraphData] = []

                for row in worksheet.data?.rows.dropFirst(1) ?? [] { // Start reading from the second row
                    if let timeString = row.cells[safe: 3]?.value,
                       let volumeString = row.cells[safe: 4]?.value,
                       let flowString = row.cells[safe: 5]?.value,
                       let time = Double(timeString),
                       let volume = Double(volumeString),
                       let flow = Double(flowString) {
                        parsedData.append(ExcelGraphData(time: time, volume: volume, flow: flow))
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

    func calculateFVCandFEV1() {
        // Calculate the maximum volume value as FVC
        fvcValue = data.map { $0.volume }.max()

        // Calculate FEV1 (Volume at 1 second)
        if let fev1Data = data.first(where: { $0.time >= 1.0 }) {
            fev1Value = fev1Data.volume
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
