import SwiftUI
import CoreXLSX

// 데이터 모델 정의
struct ExcelData: Identifiable {
    let id: Int
    let v: Int
    let t: Int
}

struct ContentView: View {
    @State private var data: [ExcelData] = []
    
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
                
//                guard let sharedStrings = try file.parseSharedStrings() else {
//                    return
//                }
                
                guard let sheetName = try file.parseWorksheetPaths().first else {
                    print("No sheets found")
                    return
                }

                let worksheet = try file.parseWorksheet(at: sheetName)
                var excelData: [ExcelData] = []
                
                for row in worksheet.data?.rows.dropFirst(1) ?? [] {
                    if let idString = row.cells[0].value,
                       let vString = row.cells[1].value,
                       let tString = row.cells[2].value,
                       let id = Int(idString),
                       let visit = Int(vString),
                       let trial = Int(tString) {
                        excelData.append(ExcelData(id: id, v: visit, t: trial))
                    }
                }
                DispatchQueue.main.async {
                    self.data = excelData
                    completion()
                }
            } catch {
                print("엑셀 파일을 읽는 데 오류가 발생했습니다: \(error)")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(data) { item in
                HStack {
                    Text("\(item.id)")  // ID 표시
                    Spacer()
                    Text("\(item.v)")  // V 값 표시
                    Spacer()
                    Text("\(item.t)")  // T 값 표시
                }
                .padding()
            }
            .onAppear {
                loadExcelData{}  // 뷰가 나타날 때 엑셀 데이터를 로드합니다.
            }
            .navigationTitle("엑셀 데이터")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
