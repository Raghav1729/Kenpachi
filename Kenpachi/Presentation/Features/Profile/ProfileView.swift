import SwiftUI

struct ProfileView: View {
    @State private var user = User.sample
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeader(user: user)
                    
                    // Quick Stats
                    QuickStatsView(user: user)
                    
                    // Menu Options
                    VStack(spacing: 0) {
                        ProfileMenuItem(
                            icon: "list.bullet",
                            title: "My List",
                            subtitle: "\(user.activeProfile?.watchlistCount ?? 0) items"
                        ) {
                            // Navigate to watchlist
                        }
                        
                        ProfileMenuItem(
                            icon: "clock",
                            title: "Watch History",
                            subtitle: "Recently watched"
                        ) {
                            // Navigate to watch history
                        }
                        
                        ProfileMenuItem(
                            icon: "arrow.down.circle",
                            title: "Downloads",
                            subtitle: "\(user.activeProfile?.downloadedCount ?? 0) downloaded"
                        ) {
                            // Navigate to downloads
                        }
                        
                        ProfileMenuItem(
                            icon: "gearshape",
                            title: "Settings",
                            subtitle: "App preferences"
                        ) {
                            showingSettings = true
                        }
                        
                        ProfileMenuItem(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            subtitle: "Get help"
                        ) {
                            // Navigate to help
                        }
                        
                        ProfileMenuItem(
                            icon: "info.circle",
                            title: "About",
                            subtitle: "App information"
                        ) {
                            // Navigate to about
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Account Section
                    VStack(spacing: 0) {
                        ProfileMenuItem(
                            icon: "person.2",
                            title: "Manage Profiles",
                            subtitle: "\(user.profiles.count) profiles"
                        ) {
                            // Navigate to profile management
                        }
                        
                        ProfileMenuItem(
                            icon: "creditcard",
                            title: "Subscription",
                            subtitle: user.subscriptionType.displayName
                        ) {
                            // Navigate to subscription
                        }
                        
                        ProfileMenuItem(
                            icon: "lock",
                            title: "Privacy",
                            subtitle: "Privacy settings"
                        ) {
                            // Navigate to privacy settings
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.black)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct ProfileHeader: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 80, height: 80)
                
                if let avatarURL = user.avatarURL {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Kenpachi")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Subscription Badge
                HStack {
                    Image(systemName: user.isPremium ? "crown.fill" : "person.fill")
                        .foregroundColor(user.isPremium ? .yellow : .gray)
                    
                    Text(user.subscriptionType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(user.isPremium ? .yellow : .gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }
}

struct QuickStatsView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                title: "Watch Time",
                value: user.formattedWatchTime,
                icon: "clock"
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.gray.opacity(0.3))
            
            StatItem(
                title: "Content",
                value: "\(user.contentWatched)",
                icon: "tv"
            )
            
            Divider()
                .frame(height: 40)
                .background(Color.gray.opacity(0.3))
            
            StatItem(
                title: "Watchlist",
                value: "\(user.activeProfile?.watchlistCount ?? 0)",
                icon: "list.bullet"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Playback Settings
                    SettingsSection(title: "Playback") {
                        SettingsToggle(title: "Autoplay", subtitle: "Automatically play next episode", isOn: .constant(true))
                        SettingsToggle(title: "Skip Intros", subtitle: "Skip opening credits", isOn: .constant(false))
                        SettingsToggle(title: "Data Saver", subtitle: "Use less data", isOn: .constant(false))
                    }
                    
                    // Download Settings
                    SettingsSection(title: "Downloads") {
                        SettingsRow(title: "Download Quality", value: "HD 1080p")
                        SettingsToggle(title: "WiFi Only", subtitle: "Only download on WiFi", isOn: .constant(true))
                        SettingsRow(title: "Storage Location", value: "Internal Storage")
                    }
                    
                    // Notifications
                    SettingsSection(title: "Notifications") {
                        SettingsToggle(title: "Push Notifications", subtitle: "Get notified about new content", isOn: .constant(true))
                        SettingsToggle(title: "Email Updates", subtitle: "Receive email notifications", isOn: .constant(false))
                    }
                    
                    // Privacy
                    SettingsSection(title: "Privacy") {
                        SettingsToggle(title: "Share Watch History", subtitle: "Help improve recommendations", isOn: .constant(true))
                        SettingsToggle(title: "Analytics", subtitle: "Help improve the app", isOn: .constant(true))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.gray)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}