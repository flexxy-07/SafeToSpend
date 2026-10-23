import SwiftUI

struct ContentView: View {
    @State private var count: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("DevNight Demo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("iOS development environment is working")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Counter: \(count)")
                .font(.title2)
                .monospacedDigit()

            HStack(spacing: 16) {
                Button(action: {
                    count -= 1
                }) {
                    Label("Decrement", systemImage: "minus")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: {
                    count += 1
                }) {
                    Label("Increment", systemImage: "plus")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
