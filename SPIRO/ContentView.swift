import SwiftUI
import CoreXLSX

// 데이터 모델 정의
struct ExcelData: Identifiable {
    let id: Int
    let visit: Int
    let trial: Int
}

struct ContentView: View {
    @State private var data: [ExcelData] = []
    @State private var rowCount: Int = 0  // 총 읽은 행의 개수를 저장할 변수
    
    // 엑셀 파일을 읽어오는 함수
    func loadExcelData(completion: @escaping () -> Void) {
        guard let filepath = Bundle.main.url(forResource: "split_data_101_to_110_with_list", withExtension: "xlsx") else {
            print("파일을 찾을 수 없습니다.")
            return
        }
        DispatchQueue.global(qos: .background).async {
            do {
                guard let file = XLSXFile(filepath: filepath.path) else {
                    print("Failed to initialize XLSXFile")
                    return
                }
                
                let worksheet = try file.parseWorksheet(at: "xl/worksheets/sheet1.xml")
                var excelData: [ExcelData] = []
                
                // 행 데이터를 읽고, excelData 배열에 추가
                for row in worksheet.data?.rows.dropFirst(1) ?? [] {
                    print(row)
                    if let idString = row.cells[0].value,
                       let vString = row.cells[1].value,
                       let tString = row.cells[2].value,
                       let id = Int(idString),
                       let visit = Int(vString),
                       let trial = Int(tString) {
                        excelData.append(ExcelData(id: id, visit: visit, trial: trial))
                    }
                }
                
                DispatchQueue.main.async {
                    self.data = excelData
                    self.rowCount = excelData.count  // 총 행 수를 업데이트
                    completion()
                }
            } catch {
                print("엑셀 파일을 읽는 데 오류가 발생했습니다: \(error)")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 화면 상단에 총 읽은 행의 개수 표시
                Text("총 \(rowCount)개의 데이터가 있습니다.")
                    .font(.headline)
                    .padding()

                // 데이터 리스트 표시
                List(data) { item in
                    HStack {
                        Text("\(item.id)")  // ID 표시
                        Spacer()
                        Text("\(item.visit)")  // V 값 표시
                        Spacer()
                        Text("\(item.trial)")  // T 값 표시
                    }
                    .padding()
                }
            }
            .onAppear {
                loadExcelData{}  // 뷰가 나타날 때 엑셀 데이터를 로드합니다.
            }
            .navigationTitle("Data List 101 to 110")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
