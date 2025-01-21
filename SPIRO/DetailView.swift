import SwiftUI
import Charts
import CoreXLSX

struct SpiroData: Identifiable{
    let id = UUID()
    let time: Double
    let volume: Double
    let flow: Double
}

struct DetailView: View {
    @State private var data: [SpiroData] = []
    @State private var animatedData: [SpiroData] = []
    @State private var fvcValue: Double? = nil
    @State private var fev1Value: Double? = nil
    @State private var evValue: Double? = nil
    @State private var newTimeZero: Double? = nil
    @State private var isEvLessThanThreshold: Bool = false
    @State private var fvc5PercentValue: Double? = nil
    @State private var highestFlowTimeAfterNewTimeZero: Double? = nil
    @State private var highestFlowTimeDifference: Double? = nil
    @State private var isFlowTimeExceedsThreshold: Bool = false
    @State private var maxFlowPoint: SpiroData? = nil
    @State private var positiveSlopePoints: [SpiroData] = []
    @State private var isPointVisible: Bool = true // Add this to control visibility of positive slope points
    @State private var flowTransitionPoints: [SpiroData] = [] // New state variable to store transition points
    @State private var flowTransitionPointsPurple: [SpiroData] = [] // New state variable for purple transition points
    
    var item: ExcelData
    
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
                            Text("Detail Info")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("ID: \(item.id)")
                                .font(.body)
                            Text("Visit: \(item.visit)")
                                .font(.body)
                            Text("Trial: \(item.trial)")
                                .font(.body)
                        }
                        
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
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("주요 수치")
                            .font(.headline)
                            .foregroundColor(.blue)
                        if let fvc = fvcValue {
                            Text("FVC Value: \(fvc) L")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let fev1 = fev1Value {
                            Text("FEV1 Value: \(fev1) L")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Text("Flow-Volume Graph")
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 5) {
                            Text("기울기가 갑자기 증가하는 경우:")
                                .font(.body)
                            Text("빨간색")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        HStack(spacing: 5) {
                            Text("흡기 타이밍:")
                                .font(.body)
                            Text("초록색")
                                .font(.body)
                                .foregroundColor(.green)
                        }
                        HStack(spacing: 5) {
                            Text("호기 타이밍:")
                                .font(.body)
                            Text("노란색")
                                .font(.body)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    
                    // Add a button to toggle the visibility of positive slope points
                    Button(action: {
                        isPointVisible.toggle() // Toggle visibility of positive slope points
                    }) {
                        Text(isPointVisible ? "Hide Points" : "Show Points")
                            .font(.body)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Chart(animatedData) {
                        LineMark(
                            x: .value("Volume", $0.volume),
                            y: .value("Flow", $0.flow)
                        )
                        .interpolationMethod(.catmullRom)
                        if let ev = evValue, let correspondingFlow = interpolateFlow(at: ev) {
                            PointMark(
                                x: .value("Volume", ev),
                                y: .value("Flow", correspondingFlow)
                            )
                            .foregroundStyle(Color.gray)
                            .annotation(position: .top) {
                                Text("New Time Zero")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        if let maxFlow = maxFlowPoint {
                            PointMark(
                                x: .value("Volume", maxFlow.volume),
                                y: .value("Flow", maxFlow.flow)
                            )
                            .foregroundStyle(Color.gray)
                            .annotation(position: .top) {
                                Text("Max Flow")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        // Add conditional rendering for positive slope points based on isPositiveSlopeVisible
                        if isPointVisible {
                            ForEach(positiveSlopePoints, id: \.volume) { point in
                                PointMark(
                                    x: .value("Volume", point.volume),
                                    y: .value("Flow", point.flow)
                                )
                                .foregroundStyle(Color.red)
                                .symbolSize(15)
                            }
                        }
                        if isPointVisible {
                            // Render Flow transition points (green)
                            ForEach(flowTransitionPoints, id: \.time) { point in
                                PointMark(
                                    x: .value("Volume", point.volume),
                                    y: .value("Flow", point.flow)
                                )
                                .foregroundStyle(Color.green) // Green for flow > 0.1 and dropping
                                .symbolSize(15)
                            }
                            
                            // Render Flow transition points (yellow)
                            ForEach(flowTransitionPointsPurple, id: \.time) { point in
                                PointMark(
                                    x: .value("Volume", point.volume),
                                    y: .value("Flow", point.flow)
                                )
                                .foregroundStyle(Color.yellow) // Yellow for flow < -0.1 and rising
                                .symbolSize(15)
                            }
                        }
                    }
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
                        if let newTimeZero = newTimeZero {
                            RuleMark(
                                x: .value("Time", newTimeZero)
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                            .foregroundStyle(Color.gray)
                            .annotation(position: .top) {
                                Text("New Time Zero")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .chartXAxisLabel("Time")
                    .chartYAxisLabel("Volume")
                    .frame(height: 300)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("검사 시작 적합 판정")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        if let ev = evValue {
                            Text("Extrapolated Volume (EV): \(ev) L")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let timeZero = newTimeZero {
                            Text("New Time Zero: \(timeZero) ms")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let fvc5Percent = fvc5PercentValue {
                            Text("5% of FVC Value: \(fvc5Percent) L")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if isEvLessThanThreshold {
                            Text("EV값이 threshold(max(FVC 5%, 150 mL)) 보다 작습니다.")
                                .font(.body)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("EV값이 threshold(max(FVC 5%, 150 mL))를 초과했습니다.")
                                .font(.body)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("검사 중 적합 판정")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        if let highestFlowTimeAfterNewTimeZero = highestFlowTimeAfterNewTimeZero {
                            Text("최고호기기류속도 도달 시점: \(highestFlowTimeAfterNewTimeZero) ms")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let highestFlowTimeDifference = highestFlowTimeDifference {
                            Text("최고호기기류속도 도달 시간: \(highestFlowTimeDifference) ms")
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if isFlowTimeExceedsThreshold {
                            Text("최고호기기류속도 도달 시간이 120ms를 초과합니다.")
                                .font(.body)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("최고호기기류속도 도달 시간이 120ms를 초과하지 않습니다.")
                                .font(.body)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                    
            }
            .padding()
        }
        .onAppear {
            loadExcelData {
                calculateFVCFEV1EVAndTimeZero()
                animateGraphDrawing()
                findMaxFlowPoint()
                checkPositiveSlopeAfterMaxFlow()
                checkFlowTransition() // Call the new function to check for flow transitions
            }
        }
        .navigationTitle("Detail")
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
                var parsedData: [SpiroData] = []

                for row in worksheet.data?.rows.dropFirst(1) ?? [] { // Start reading from the second row
                    if let timeString = row.cells[3].value,
                       let volumeString = row.cells[4].value,
                       let flowString = row.cells[5].value,
                       let time = Double(timeString),
                       let volume = Double(volumeString),
                       let flow = Double(flowString) {
                        parsedData.append(SpiroData(time: time, volume: volume, flow: flow))
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

    // Function to check for flow transitions
    func checkFlowTransition() {
        flowTransitionPoints = []
        flowTransitionPointsPurple = []
        guard let newTimeZero = newTimeZero else { return }

        // Only check for flow transitions before the newTimeZero
        let preNewTimeZeroData = data.filter { $0.time < newTimeZero }
        
        for i in 1..<preNewTimeZeroData.count {
            let prev = preNewTimeZeroData[i - 1]
            let current = preNewTimeZeroData[i]
            
            // Check for Flow > 0.1 and decreasing (green)
            if prev.flow >= 0.1 && current.flow < 0.1 {
                flowTransitionPoints.append(current) // Green point
            }
            
            // Check for Flow < -0.1 and increasing (purple)
            if prev.flow <= -0.1 && current.flow > -0.1 {
                flowTransitionPointsPurple.append(current) // Purple point
            }
        }
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

    func animateGraphDrawing() {
        // 에니메이션 사용시에 아래 코드
//        animatedData = []
//        for (index, point) in data.enumerated() {
//            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) { // Faster animation
//                animatedData.append(point)
//            }
//        }
        
        // 에니메이션 필요 없을 시에 아래 코드
        animatedData = data
    }
    
    func findMaxFlowPoint() {
        maxFlowPoint = data.max(by: { $0.flow < $1.flow })
    }

    func checkPositiveSlopeAfterMaxFlow() { // flow-volume curve에서 기울기가 양수가 되는 시점을 찾는 메소드
        guard let maxFlowIndex = data.firstIndex(where: { $0.id == maxFlowPoint?.id }) else { return }
        positiveSlopePoints = []
        for i in maxFlowIndex..<(data.count - 1) {
            let p1 = data[i]
            let p2 = data[i + 1]
            if p1.flow <= 0 || p2.flow <= 0 {
                break
            }
            let slope = (p2.flow - p1.flow) / (p2.volume - p1.volume)
            if slope > 0 {
                positiveSlopePoints.append(p2)
            }
        }
    }
    
    func interpolateFlow(at volume: Double) -> Double? {
        guard let lower = data.last(where: { $0.volume <= volume }),
              let upper = data.first(where: { $0.volume > volume }),
              lower.volume != upper.volume else {
            return nil
        }

        let slope = (upper.flow - lower.flow) / (upper.volume - lower.volume)
        return lower.flow + slope * (volume - lower.volume)
    }
}
