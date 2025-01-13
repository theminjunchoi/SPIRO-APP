import SwiftUI
import CoreXLSX

struct DetailView: View {
    var item: ExcelData
    
    var body: some View {
        VStack {
            Text("ID: \(item.id)")
                .font(.title)
                .padding()
            Text("Visit: \(item.visit)")
                .font(.title2)
                .padding()
            Text("Trial: \(item.trial)")
                .font(.title2)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Detail")
    }
}
