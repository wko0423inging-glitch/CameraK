import SwiftUI

struct HistogramView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Histogram")
                .font(.caption)
                .foregroundColor(.white)

            HStack(alignment: .bottom, spacing: 1) {
                ForEach(0..<256, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gray.opacity(Double(index) / 256.0))
                        .frame(height: CGFloat(Int.random(in: 5...30)))
                }
            }
            .frame(height: 40)
        }
    }
}

struct HistogramView_Previews: PreviewProvider {
    static var previews: some View {
        HistogramView()
    }
}
