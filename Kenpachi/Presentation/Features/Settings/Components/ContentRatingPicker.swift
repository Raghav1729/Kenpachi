// ContentRatingPicker.swift
// A view for selecting the content rating for parental controls.

import SwiftUI

struct ContentRatingPicker: View {
  @Binding var selection: ContentRating

  var body: some View {
    List {
      ForEach(ContentRating.allCases, id: \.self) { rating in
        Button {
          selection = rating
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: .spacingXS) {
              Text(rating.displayName)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

              Text(descriptionForRating(rating))
                .font(.captionLarge)
                .foregroundColor(.textSecondary)
            }

            Spacer()

            if selection == rating {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.parental_controls.allowed_rating")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func descriptionForRating(_ rating: ContentRating) -> String {
    switch rating {
    case .unrestricted: return "All content allowed"
    case .pg13: return "Parental guidance for children under 13"
    case .pg: return "Parental guidance suggested"
    case .g: return "General audiences, all ages"
    }
  }
}
