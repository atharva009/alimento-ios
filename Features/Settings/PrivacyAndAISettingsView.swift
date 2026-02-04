//
//  PrivacyAndAISettingsView.swift
//  Alimento
//
//  Created on Phase 10
//

import SwiftUI

struct PrivacyAndAISettingsView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Storage")
                        .font(.headline)
                    
                    Text("All your data is stored locally on your device:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Inventory items", systemImage: "cabinet.fill")
                        Label("Logged dishes", systemImage: "fork.knife")
                        Label("Planned meals", systemImage: "calendar")
                        Label("Grocery lists", systemImage: "cart.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Local Storage")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Integration")
                        .font(.headline)
                    
                    Text("When using AI features, only summary information is sent to Google's Gemini API:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Item names and quantities (not personal notes)", systemImage: "checkmark.circle.fill")
                        Label("Meal preferences and dietary restrictions", systemImage: "checkmark.circle.fill")
                        Label("Planned meal summaries", systemImage: "checkmark.circle.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text("What is NOT sent:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Raw personal notes or sensitive information", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Label("Full conversation history (stored locally only)", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("AI Data Usage")
            } footer: {
                Text("Raw prompts and AI responses are not persisted by default. Your data remains private and secure.")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mock Mode")
                        .font(.headline)
                    
                    if AIConfiguration.shared.hasAPIKey {
                        Label("AI features are enabled with your API key", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("AI features are running in mock mode (no API key configured)", systemImage: "info.circle.fill")
                            .foregroundStyle(.orange)
                        
                        Text("To enable live AI features, configure GEMINI_API_KEY in your build settings. See README for setup instructions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("AI Status")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Health & Wellness Disclaimer")
                        .font(.headline)
                    
                    Text("Alimento provides general wellness guidance and meal planning assistance only. This app is not a substitute for professional medical advice, diagnosis, or treatment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition or dietary needs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Medical Disclaimer")
            }
        }
        .navigationTitle("Privacy & AI")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        PrivacyAndAISettingsView()
    }
}

