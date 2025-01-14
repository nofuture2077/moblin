import SwiftUI

struct ValueEditView: View {
    var title: String
    @State var value: String
    var minimum: Double
    var maximum: Double
    var onSubmit: (String) -> String
    var increment: Double = 1
    var unit: String?

    func add(offset: Double) {
        if var value = Double(value) {
            value += offset
            if value >= minimum && value <= maximum {
                self.value = String(value)
            }
        }
    }

    var body: some View {
        HStack {
            HStack {
                Text(title)
                Spacer()
            }
            .frame(width: 70)
            TextField("", text: $value, onEditingChanged: { isEditing in
                if !isEditing {
                    value = onSubmit(value.trim())
                }
            })
            .onSubmit {
                value = onSubmit(value.trim())
            }
            if let unit {
                Text(unit)
            }
            Divider()
            Button(action: {
                add(offset: -increment)
                value = onSubmit(value.trim())
            }, label: {
                Text("-")
                    .frame(width: 40)
                    .font(.system(size: 25))
            })
            Divider()
            Button(action: {
                add(offset: increment)
                value = onSubmit(value.trim())
            }, label: {
                Text("+")
                    .frame(width: 40)
                    .font(.system(size: 25))
            })
            Divider()
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
