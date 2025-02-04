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
    @State private var fvcValue: Double? = nil
    @State private var fev1Value: Double? = nil
    @State private var evValue: Double? = nil
    @State private var newTimeZero: Double? = nil
    @State private var isEvLessThanThreshold: Bool = false
    @State private var fvc5PercentValue: Double? = nil
    @State private var highestFlowTimeAfterNewTimeZero: Double? = nil
    @State private var highestFlowTimeDifference: Double? = nil
    @State private var isFlowTimeExceedsThreshold: Bool = false
    @State private var exhaleToInhale: [AnimeData] = []
    @State private var inhaleToExhale: [AnimeData] = []
    
    var item: VisualData
    
    @State private var showText = false
    @State private var displayedText = ""
    
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
                    // exhaleToInhale 시점에 "들이마시세요!" 표시
                    ForEach(exhaleToInhale, id: \.id) { point in
                        GeometryReader { geometry in
                            Text("들이마시세요!")
                                .foregroundColor(.green)
                                .position(x: geometry.size.width * CGFloat(point.time) / CGFloat(animatedData.last?.time ?? 1), y: geometry.size.height - 40)
                                .opacity(showText ? 1 : 0)
                                .onAppear {
                                    if !showText {
                                        withAnimation(.easeInOut(duration: 3)) {
                                            displayedText = "들이마시세요!"
                                            showText = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            withAnimation(.easeInOut(duration: 3)) {
                                                showText = false
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    
                    // inhaleToExhale 시점에 "내쉬세요!" 표시
                    ForEach(inhaleToExhale, id: \.id) { point in
                        GeometryReader { geometry in
                            Text("내쉬세요!")
                                .foregroundColor(.yellow)
                                .position(x: geometry.size.width * CGFloat(point.time) / CGFloat(animatedData.last?.time ?? 1), y: geometry.size.height - 40)
                                .opacity(showText ? 1 : 0)
                                .onAppear {
                                    if !showText {
                                        withAnimation(.easeInOut(duration: 3)) {
                                            displayedText = "내쉬세요!"
                                            showText = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            withAnimation(.easeInOut(duration: 3)) {
                                                showText = false
                                            }
                                        }
                                    }
                                }
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
                        
//                        // Render Flow transition points (green)
//                        ForEach(exhaleToInhale, id: \.time) { point in
//                            PointMark(
//                                x: .value("Volume", point.volume),
//                                y: .value("Flow", point.flow)
//                            )
//                            .foregroundStyle(Color.green) // Green for flow > 0.1 and dropping
//                            .symbolSize(15)
//                        }
//                        
//                        // Render Flow transition points (yellow)
//                        ForEach(inhaleToExhale, id: \.time) { point in
//                            PointMark(
//                                x: .value("Volume", point.volume),
//                                y: .value("Flow", point.flow)
//                            )
//                            .foregroundStyle(Color.yellow) // Yellow for flow < -0.1 and rising
//                            .symbolSize(15)
//                        }
                        
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
                calculateFVCFEV1EVAndTimeZero()
                animateGraphDrawing()
                checkFlowTransition()
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
    
    func interpolateY(at x: Double) -> Double? {
        guard let lower = data.last(where: { $0.time <= x }),
              let upper = data.first(where: { $0.time > x }),
              lower.time != upper.time else {
            return nil
        }

        let slope = (upper.volume - lower.volume) / (upper.time - lower.time)
        return lower.volume + slope * (x - lower.time)
    }
    
    func findMaxSlopePoint() -> (slope: Double, intercept: Double)? {
        guard data.count > 1 else { return nil }
        var maxSlope = Double.leastNormalMagnitude
        var bestPoint: (slope: Double, intercept: Double)? = nil

        for i in 0..<(data.count - 1) {
            let p1 = data[i]
            let p2 = data[i + 1]
            let slope = (p2.volume - p1.volume) / (p2.time - p1.time)
            if slope > maxSlope {
                maxSlope = slope
                let intercept = p1.volume - slope * p1.time
                bestPoint = (slope, intercept)
            }
        }

        return bestPoint
    }
    
    func calculateFVCFEV1EVAndTimeZero() {
        // Calculate the maximum volume value as FVC
        fvcValue = data.map { $0.volume }.max()

        // Calculate FEV1 (Volume at 1 second)
        if let fev1Data = data.first(where: { $0.time >= 1.0 }) {
            fev1Value = fev1Data.volume
        }

        // Calculate New Time Zero and EV using max slope point
        if let maxSlopePoint = findMaxSlopePoint() {
            let slope = maxSlopePoint.slope
            let intercept = maxSlopePoint.intercept

            newTimeZero = -intercept / slope

            if let newTimeZero = newTimeZero {
                evValue = interpolateY(at: newTimeZero)
            }
        }

        // Calculate 5% of FVC for threshold
        if let fvc = fvcValue {
            fvc5PercentValue = fvc * 0.05
        }

        // Calculate the threshold (max of FVC 5% or 150mL)
        let threshold = max(fvc5PercentValue ?? 0.0, 0.150)

        // Check if EV is less than the threshold (5% of FVC or 150mL)
        if let ev = evValue {
            isEvLessThanThreshold = ev < threshold
        }

        // Find the highest flow after newTimeZero
        if let newTimeZero = newTimeZero {
            if let highestFlowData = data.filter({ $0.time > newTimeZero }).max(by: { $0.flow < $1.flow }) {
                highestFlowTimeAfterNewTimeZero = highestFlowData.time
            }

            // Calculate the time difference between highestFlowTimeAfterNewTimeZero and newTimeZero
            if let highestFlowTimeAfterNewTimeZero = highestFlowTimeAfterNewTimeZero {
                highestFlowTimeDifference = highestFlowTimeAfterNewTimeZero - newTimeZero
                // Check if the time difference exceeds 120ms
                isFlowTimeExceedsThreshold = highestFlowTimeDifference! > 120.0 // 120 ms directly
            }
        }
    }
    
    func checkFlowTransition() {
        exhaleToInhale = []
        inhaleToExhale = []
        guard let newTimeZero = newTimeZero else { return }

        // Only check for flow transitions before the newTimeZero
        let preNewTimeZeroData = data.filter { $0.time < newTimeZero }
        
        for i in 1..<preNewTimeZeroData.count {
            let prev = preNewTimeZeroData[i - 1]
            let current = preNewTimeZeroData[i]
            
            // Check for Flow > 0.1 and decreasing (green)
            if prev.flow >= 0.1 && current.flow < 0.1 {
                exhaleToInhale.append(current) // Green point
            }
            
            // Check for Flow < -0.1 and increasing (purple)
            if prev.flow <= -0.1 && current.flow > -0.1 {
                inhaleToExhale.append(current) // Purple point
            }
        }
    }
}
