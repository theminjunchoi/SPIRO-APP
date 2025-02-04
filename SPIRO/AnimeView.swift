import SwiftUI
import Charts
import CoreXLSX

struct AnimeData: Identifiable{
    let id = UUID()
    let time: Double
    let volume: Double
    let flow: Double
}

struct AnimeView: View {
    @State private var data: [AnimeData] = []
    @State private var animatedData: [AnimeData] = []
    
    var item: VisualData
    
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
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Volume-Time Graph Current:")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("Time: \(lastData.time)")
                                .font(.body)
                            Text("Volume: \(lastData.volume)")
                                .font(.body)
                        }
                    }
                    
                    // 여기에 flow 값에 맞춰 원의 크기를 그려주는 부분을 추가
                    if let lastData = animatedData.last {
                        // flow 값이 음수일 경우 0으로 설정하고, 양수일 경우 기존 방식대로 크기를 계산
                        let flowValue = max(CGFloat(lastData.flow) * 30 + 100, 10)
                        
                        // 원을 가운데 정렬하기 위해 Spacer()를 사용
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.blue)
                                .frame(width: flowValue, height: flowValue)
                                .padding(.top, 20)
                            Spacer()
                        }
                        .frame(height: 300)
                    }
                    
                    Text("Flow-Volume Graph")
                        .font(.title)
                    
                    Chart(animatedData) {
                        LineMark(
                            x: .value("Volume", $0.volume),
                            y: .value("Flow", $0.flow)
                        )
                        .interpolationMethod(.catmullRom)
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
                animateGraphDrawing()
            }
        }
        .navigationTitle("Detail \(item.id) / \(item.visit) / \(item.trial)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
    
    func loadExcelData(completion: @escaping () -> Void) {
        guard let fileURL = Bundle.main.url(forResource: "split_data_101_to_110_with_list",
            withExtension: "xlsx") else {
            print("File not found")
            return
        }

        DispatchQueue.global(qos: .background).async {
            do {
                guard let file = XLSXFile(filepath: fileURL.path) else {
                    print("Failed to initialize XLSXFile")
                    return
                }

                let sheetName = "xl/worksheets/sheet" + String(item.index) + ".xml"
                
                print(sheetName)
                let worksheet = try file.parseWorksheet(at: sheetName)
                var parsedData: [AnimeData] = []

                for row in worksheet.data?.rows.dropFirst(1) ?? [] { // Start reading from the second row
                    if let timeString = row.cells[3].value,
                       let volumeString = row.cells[4].value,
                       let flowString = row.cells[5].value,
                       let time = Double(timeString),
                       let volume = Double(volumeString),
                       let flow = Double(flowString) {
                        parsedData.append(AnimeData(time: time, volume: volume, flow: flow))
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
        // 에니메이션 사용시에 아래 코드
        animatedData = []
        for (index, point) in data.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) { // Faster animation
                animatedData.append(point)
            }
        }
        
        // 에니메이션 필요 없을 시에 아래 코드
//        animatedData = data
    }
}
