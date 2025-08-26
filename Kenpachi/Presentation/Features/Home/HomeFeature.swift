import ComposableArchitecture
import Foundation

struct HomeFeature: Reducer {
  struct State: Equatable {
    var isLoading = false
    var heroContent: Content?
    var contentSections: [ContentSectionData] = []
    var error: String?
  }

  enum Action: Equatable {
    case onAppear
    case refresh
    case loadContent
    case contentLoaded([ContentSectionData])
    case heroContentLoaded(Content)
    case contentTapped(Content)
    case heroContentTapped(Content)
    case errorOccurred(String)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear, .refresh:
        return .send(.loadContent)

      case .loadContent:
        state.isLoading = true
        state.error = nil
        return .run { send in
          // Simulate network delay
          try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

          // Load hero content
          await send(.heroContentLoaded(MockData.getHeroContent()))

          // Load content sections
          await send(.contentLoaded(MockData.getContentSections()))
        }

      case .contentLoaded(let sections):
        state.isLoading = false
        state.contentSections = sections
        return .none

      case .heroContentLoaded(let content):
        state.heroContent = content
        return .none

      case .contentTapped, .heroContentTapped:
        // Navigate to content detail
        return .none

      case .errorOccurred(let error):
        state.isLoading = false
        state.error = error
        return .none
      }
    }
  }
}
