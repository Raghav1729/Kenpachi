import SwiftUI

struct DisneyBrandSection: View {
    let onBrandTap: (DisneyBrand) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Explore by Brand")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DisneyBrand.allCases, id: \.self) { brand in
                        DisneyBrandCard(brand: brand) {
                            onBrandTap(brand)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct DisneyBrandCard: View {
    let brand: DisneyBrand
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Brand gradient background
                LinearGradient(
                    colors: brand.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Brand logo/icon
                VStack {
                    Image(systemName: brand.iconName)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(brand.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .frame(width: 120, height: 80)
            .cornerRadius(12)
            .shadow(color: brand.shadowColor, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

enum DisneyBrand: String, CaseIterable {
    case disney = "disney"
    case pixar = "pixar"
    case marvel = "marvel"
    case starWars = "star_wars"
    case nationalGeographic = "national_geographic"
    case star = "star"
    
    var displayName: String {
        switch self {
        case .disney:
            return "Disney"
        case .pixar:
            return "Pixar"
        case .marvel:
            return "Marvel"
        case .starWars:
            return "Star Wars"
        case .nationalGeographic:
            return "National\nGeographic"
        case .star:
            return "Star"
        }
    }
    
    var iconName: String {
        switch self {
        case .disney:
            return "castle.fill"
        case .pixar:
            return "lightbulb.fill"
        case .marvel:
            return "shield.fill"
        case .starWars:
            return "star.fill"
        case .nationalGeographic:
            return "globe.americas.fill"
        case .star:
            return "star.circle.fill"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .disney:
            return [Color.blue, Color.purple]
        case .pixar:
            return [Color.yellow, Color.orange]
        case .marvel:
            return [Color.red, Color.black]
        case .starWars:
            return [Color.black, Color.yellow]
        case .nationalGeographic:
            return [Color.yellow, Color.green]
        case .star:
            return [Color.gray, Color.blue]
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .disney:
            return Color.blue.opacity(0.3)
        case .pixar:
            return Color.yellow.opacity(0.3)
        case .marvel:
            return Color.red.opacity(0.3)
        case .starWars:
            return Color.yellow.opacity(0.3)
        case .nationalGeographic:
            return Color.yellow.opacity(0.3)
        case .star:
            return Color.blue.opacity(0.3)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.black
        DisneyBrandSection { brand in
            print("Tapped: \(brand.displayName)")
        }
    }
}