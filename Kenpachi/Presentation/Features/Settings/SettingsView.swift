// SettingsView.swift
// Settings screen UI with comprehensive options
// Disney+ Hotstar inspired design with full integration

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  @SwiftUI.Environment(\.dismiss) var dismiss: DismissAction

  var body: some View {
    NavigationStack {
      contentView
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              dismiss()
            }
            .foregroundColor(.primaryBlue)
          }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
          store.send(.onAppear)
        }
    }
  }

  @ViewBuilder
  private var contentView: some View {
    ZStack {
      Color.appBackground.ignoresSafeArea()

      if store.isLoadingSettings {
        LoadingView(message: "Loading settings...")
      } else {
        ScrollView {
          VStack(spacing: .spacingL) {
            generalSection
            securitySection
            contentPreferencesSection
            parentalControlsSection
            playerSettingsSection
            downloadSettingsSection
            notificationsSection
            streamingSection
            privacySection
            storageSection
            aboutSection
            supportButton
          }
          .padding(.bottom, .spacingL)
        }
      }
    }
  }

  // MARK: - General Section
  private var generalSection: some View {
    SettingsSection(title: "General") {
      SettingsRow(
        icon: "paintbrush.fill",
        title: "Theme",
        value: store.selectedTheme.displayName
      ) {
        ThemePicker(selection: $store.selectedTheme.sending(\.themeChanged))
      }

      SettingsRow(
        icon: "paintpalette.fill",
        title: "Accent Color",
        value: store.accentColor.displayName
      ) {
        AccentColorPicker(selection: $store.accentColor.sending(\.accentColorChanged))
      }
    }
  }

  // MARK: - Security Section
  private var securitySection: some View {
    SettingsSection(title: "Security") {
      SettingsToggleRow(
        icon: "faceid",
        title: "Biometric Authentication",
        subtitle: "Use Face ID or Touch ID to unlock",
        isOn: $store.biometricAuthEnabled.sending(\.biometricAuthToggled)
      )

      if store.biometricAuthEnabled {
        SettingsRow(
          icon: "lock.fill",
          title: "Auto Lock",
          value: store.autoLockTimeout.displayName
        ) {
          AutoLockPicker(selection: $store.autoLockTimeout.sending(\.autoLockTimeoutChanged))
        }
      }
    }
  }

  // MARK: - Content Preferences Section
  private var contentPreferencesSection: some View {
    SettingsSection(title: "Content Preferences") {
      SettingsRow(
        icon: "server.rack",
        title: "Scraper Source",
        subtitle: "Default content provider",
        value: store.defaultScraperSource.displayName
      ) {
        ScraperSourcePicker(
          selection: $store.defaultScraperSource.sending(\.scraperSourceChanged))
      }

      SettingsRow(
        icon: "globe",
        title: "Preferred Language",
        value: store.preferredLanguage.displayName
      ) {
        LanguagePicker(selection: $store.preferredLanguage.sending(\.preferredLanguageChanged))
      }

      SettingsToggleRow(
        icon: "18.circle.fill",
        title: "Show Adult Content",
        subtitle: "Display mature content in search results",
        isOn: $store.showAdultContent.sending(\.showAdultContentToggled)
      )
    }
  }

  // MARK: - Parental Controls Section
  private var parentalControlsSection: some View {
    SettingsSection(title: "Parental Controls") {
      SettingsToggleRow(
        icon: "person.2.fill",
        title: "Enable Parental Controls",
        isOn: $store.parentalControlsEnabled.sending(\.parentalControlsToggled)
      )

      if store.parentalControlsEnabled {
        SettingsRow(
          icon: "shield.lefthalf.filled",
          title: "Allowed Content Rating",
          value: store.allowedContentRating.displayName
        ) {
          ContentRatingPicker(
            selection: $store.allowedContentRating.sending(\.allowedContentRatingChanged))
        }
      }
    }
  }

  // MARK: - Player Settings Section
  private var playerSettingsSection: some View {
    SettingsSection(title: "Player Settings") {
      SettingsToggleRow(
        icon: "play.circle.fill",
        title: "Auto-Play Next Episode",
        subtitle: "Automatically play next episode",
        isOn: $store.autoPlayEnabled.sending(\.autoPlayToggled)
      )

      SettingsToggleRow(
        icon: "film.fill",
        title: "Auto-Play Trailers",
        subtitle: "Play trailers on detail pages",
        isOn: $store.autoPlayTrailers.sending(\.autoPlayTrailersToggled)
      )

      SettingsRow(
        icon: "video.fill",
        title: "Default Quality",
        value: store.defaultQuality.displayName
      ) {
        QualityPicker(selection: $store.defaultQuality.sending(\.defaultQualityChanged))
      }

      SettingsToggleRow(
        icon: "captions.bubble.fill",
        title: "Subtitles",
        isOn: $store.subtitlesEnabled.sending(\.subtitlesToggled)
      )

      if store.subtitlesEnabled {
        SettingsRow(
          icon: "text.bubble.fill",
          title: "Subtitle Language",
          value: store.preferredSubtitleLanguage.displayName
        ) {
          SubtitleLanguagePicker(
            selection: $store.preferredSubtitleLanguage.sending(\.subtitleLanguageChanged))
        }
      }

      SettingsRow(
        icon: "speaker.wave.2.fill",
        title: "Audio Language",
        value: store.preferredAudioLanguage.displayName
      ) {
        AudioLanguagePicker(
          selection: $store.preferredAudioLanguage.sending(\.audioLanguageChanged))
      }

      SettingsRow(
        icon: "speedometer",
        title: "Playback Speed",
        value: store.playbackSpeed.displayName
      ) {
        PlaybackSpeedPicker(selection: $store.playbackSpeed.sending(\.playbackSpeedChanged))
      }
    }
  }

  // MARK: - Download Settings Section
  private var downloadSettingsSection: some View {
    SettingsSection(title: "Downloads") {
      SettingsRow(
        icon: "arrow.down.circle.fill",
        title: "Download Quality",
        value: store.downloadQuality.displayName
      ) {
        QualityPicker(selection: $store.downloadQuality.sending(\.downloadQualityChanged))
      }

      SettingsToggleRow(
        icon: "antenna.radiowaves.left.and.right",
        title: "Download Over Cellular",
        subtitle: "Allow downloads on mobile data",
        isOn: $store.downloadOverCellular.sending(\.downloadOverCellularToggled)
      )

      SettingsToggleRow(
        icon: "trash.fill",
        title: "Auto-Delete Watched",
        subtitle: "Remove downloads after watching",
        isOn: $store.autoDeleteWatchedDownloads.sending(\.autoDeleteWatchedToggled)
      )
    }
  }

  // MARK: - Notifications Section
  private var notificationsSection: some View {
    SettingsSection(title: "Notifications") {
      SettingsToggleRow(
        icon: "bell.fill",
        title: "Push Notifications",
        subtitle: "Receive app notifications",
        isOn: $store.pushNotificationsEnabled.sending(\.pushNotificationsToggled)
      )

      if store.pushNotificationsEnabled {
        SettingsToggleRow(
          icon: "sparkles",
          title: "New Content",
          isOn: $store.newContentNotifications.sending(\.newContentNotificationsToggled)
        )

        SettingsToggleRow(
          icon: "checkmark.circle.fill",
          title: "Download Complete",
          isOn: $store.downloadCompleteNotifications.sending(\.downloadNotificationsToggled)
        )

        SettingsToggleRow(
          icon: "star.fill",
          title: "Recommendations",
          isOn: $store.recommendationNotifications.sending(\.recommendationNotificationsToggled)
        )
      }
    }
  }

  // MARK: - Streaming Section
  private var streamingSection: some View {
    SettingsSection(title: "Streaming") {
      SettingsToggleRow(
        icon: "airplayvideo",
        title: "AirPlay",
        subtitle: "Stream to Apple TV and AirPlay devices",
        isOn: $store.airPlayEnabled.sending(\.airPlayToggled)
      )

      SettingsToggleRow(
        icon: "tv.fill",
        title: "Chromecast",
        subtitle: "Cast to Chromecast devices",
        isOn: $store.chromecastEnabled.sending(\.chromecastToggled)
      )

      SettingsToggleRow(
        icon: "pip.fill",
        title: "Picture in Picture",
        subtitle: "Watch while using other apps",
        isOn: $store.pipEnabled.sending(\.pipToggled)
      )
    }
  }

  // MARK: - Privacy Section
  private var privacySection: some View {
    SettingsSection(title: "Privacy") {
      SettingsToggleRow(
        icon: "chart.bar.fill",
        title: "Analytics",
        subtitle: "Help improve the app",
        isOn: $store.analyticsEnabled.sending(\.analyticsToggled)
      )

      SettingsToggleRow(
        icon: "exclamationmark.triangle.fill",
        title: "Crash Reporting",
        subtitle: "Send crash reports",
        isOn: $store.crashReportingEnabled.sending(\.crashReportingToggled)
      )

      SettingsToggleRow(
        icon: "sparkles.rectangle.stack.fill",
        title: "Personalized Recommendations",
        subtitle: "Based on your viewing history",
        isOn: $store.personalizedRecommendations.sending(\.personalizedRecommendationsToggled)
      )

      SettingsToggleRow(
        icon: "clock.arrow.circlepath",
        title: "Search History",
        subtitle: "Save recent searches",
        isOn: $store.searchHistoryEnabled.sending(\.searchHistoryToggled)
      )

      if store.searchHistoryEnabled {
        SettingsButtonRow(
          icon: "trash.fill",
          title: "Clear Search History",
          style: .destructive
        ) {
          store.send(.clearSearchHistoryTapped)
        }
      }
    }
  }

  // MARK: - Storage Section
  private var storageSection: some View {
    SettingsSection(title: "Storage") {
      StorageInfoRow(
        icon: "internaldrive.fill",
        title: "Total Used",
        size: store.totalStorageUsed
      )

      StorageInfoRow(
        icon: "square.stack.3d.up.fill",
        title: "Cache",
        size: store.cacheSize
      )

      StorageInfoRow(
        icon: "photo.stack.fill",
        title: "Image Cache",
        size: store.imageCacheSize
      )

      StorageInfoRow(
        icon: "arrow.down.circle.fill",
        title: "Downloads",
        size: store.downloadsSize
      )

      SettingsButtonRow(
        icon: "trash.fill",
        title: "Clear Cache",
        style: .destructive,
        isLoading: store.isClearingCache
      ) {
        store.send(.clearCacheTapped)
      }

      SettingsButtonRow(
        icon: "trash.fill",
        title: "Clear Image Cache",
        style: .destructive,
        isLoading: store.isClearingImageCache
      ) {
        store.send(.clearImageCacheTapped)
      }
    }
  }

  // MARK: - About Section
  private var aboutSection: some View {
    SettingsSection(title: "About") {
      SettingsInfoRow(
        icon: "info.circle.fill",
        title: "Version",
        value: "\(store.appVersion) (\(store.buildNumber))"
      )

      SettingsButtonRow(
        icon: "questionmark.circle.fill",
        title: "Help & Support"
      ) {
        store.send(.helpTapped)
      }

      SettingsButtonRow(
        icon: "doc.text.fill",
        title: "Privacy Policy"
      ) {
        store.send(.privacyPolicyTapped)
      }

      SettingsButtonRow(
        icon: "doc.plaintext.fill",
        title: "Terms of Service"
      ) {
        store.send(.termsOfServiceTapped)
      }
    }
  }

  // MARK: - Support Button
  private var supportButton: some View {
    Button {
      store.send(.supportTapped)
    } label: {
      HStack(spacing: .spacingS) {
        Image(systemName: "heart.fill")
          .font(.labelLarge)
        Text("Support Development")
          .font(.labelLarge)
          .fontWeight(.medium)
      }
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, .spacingM)
      .background(Color.primaryBlue)
      .cornerRadius(.radiusM)
    }
    .padding(.horizontal, .spacingM)
    .padding(.vertical, .spacingS)
  }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      Text(title)
        .font(.labelMedium)
        .foregroundColor(.textSecondary)
        .textCase(.uppercase)
        .tracking(0.5)
        .padding(.horizontal, .spacingM)
        .padding(.top, .spacingXS)

      VStack(spacing: 0) {
        content()
      }
      .background(Color.cardBackground)
      .cornerRadius(.radiusM)
      .padding(.horizontal, .spacingM)
    }
  }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
  let icon: String
  let title: String
  var subtitle: String?
  var value: String?

  var body: some View {
    HStack(spacing: .spacingS + 4) {
      Image(systemName: icon)
        .font(.labelLarge)
        .foregroundColor(.primaryBlue)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: .spacingXS / 2) {
        Text(title)
          .font(.bodyMedium)
          .foregroundColor(.textPrimary)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.captionMedium)
            .foregroundColor(.textSecondary)
        }
      }

      Spacer()

      if let value = value {
        Text(value)
          .font(.captionLarge)
          .foregroundColor(.textSecondary)
      }
    }
    .padding(.horizontal, .spacingM)
    .padding(.vertical, .spacingS + 4)
    .background(Color.cardBackground)
  }
}

// MARK: - Settings Row
struct SettingsRow<Destination: View>: View {
  let icon: String
  let title: String
  var subtitle: String?
  var value: String?
  @ViewBuilder var destination: () -> Destination

  var body: some View {
    NavigationLink {
      destination()
    } label: {
      HStack(spacing: .spacingS + 4) {
        Image(systemName: icon)
          .font(.labelLarge)
          .foregroundColor(.primaryBlue)
          .frame(width: 24)

        VStack(alignment: .leading, spacing: .spacingXS / 2) {
          Text(title)
            .font(.bodyMedium)
            .foregroundColor(.textPrimary)

          if let subtitle = subtitle {
            Text(subtitle)
              .font(.captionMedium)
              .foregroundColor(.textSecondary)
          }
        }

        Spacer()

        if let value = value {
          Text(value)
            .font(.captionLarge)
            .foregroundColor(.textSecondary)
        }

        Image(systemName: "chevron.right")
          .font(.captionMedium)
          .foregroundColor(.textTertiary)
      }
      .padding(.horizontal, .spacingM)
      .padding(.vertical, .spacingS + 4)
      .background(Color.cardBackground)
    }
  }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
  let icon: String
  let title: String
  var subtitle: String?
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: .spacingS + 4) {
      Image(systemName: icon)
        .font(.labelLarge)
        .foregroundColor(.primaryBlue)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: .spacingXS / 2) {
        Text(title)
          .font(.bodyMedium)
          .foregroundColor(.textPrimary)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.captionMedium)
            .foregroundColor(.textSecondary)
        }
      }

      Spacer()

      Toggle("", isOn: $isOn)
        .labelsHidden()
        .tint(.primaryBlue)
    }
    .padding(.horizontal, .spacingM)
    .padding(.vertical, .spacingS + 4)
    .background(Color.cardBackground)
  }
}

// MARK: - Settings Button Row
struct SettingsButtonRow: View {
  let icon: String
  let title: String
  var style: ButtonStyle = .normal
  var isLoading: Bool = false
  let action: () -> Void

  enum ButtonStyle {
    case normal
    case destructive
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: .spacingS + 4) {
        Image(systemName: icon)
          .font(.labelLarge)
          .foregroundColor(style == .destructive ? .error : .primaryBlue)
          .frame(width: 24)

        Text(title)
          .font(.bodyMedium)
          .foregroundColor(style == .destructive ? .error : .textPrimary)

        Spacer()

        if isLoading {
          ProgressView()
            .tint(.textSecondary)
        } else {
          Image(systemName: "chevron.right")
            .font(.captionMedium)
            .foregroundColor(.textTertiary)
        }
      }
      .padding(.horizontal, .spacingM)
      .padding(.vertical, .spacingS + 4)
      .background(Color.cardBackground)
    }
    .disabled(isLoading)
  }
}

// MARK: - Storage Info Row
struct StorageInfoRow: View {
  let icon: String
  let title: String
  let size: Int64

  var body: some View {
    HStack(spacing: .spacingS + 4) {
      Image(systemName: icon)
        .font(.labelLarge)
        .foregroundColor(.primaryBlue)
        .frame(width: 24)

      Text(title)
        .font(.bodyMedium)
        .foregroundColor(.textPrimary)

      Spacer()

      Text(formatBytes(size))
        .font(.captionLarge)
        .foregroundColor(.textSecondary)
    }
    .padding(.horizontal, .spacingM)
    .padding(.vertical, .spacingS + 4)
    .background(Color.cardBackground)
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}
