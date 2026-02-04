//
//  AssistantView.swift
//  Alimento
//
//  Created on Phase 8
//

import SwiftUI
import SwiftData

struct AssistantView: View {
    @EnvironmentObject private var services: ServicesContainer
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: AssistantViewModel?
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                    // Messages list
                if let vm = viewModel {
                    if vm.messages.filter({ $0.role != .system }).isEmpty && vm.state == .idle {
                        EmptyAssistantView()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(vm.messages.filter { $0.role != .system }) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                    
                                    // Loading indicator
                                    if vm.state == .thinking || vm.state == .executingTool {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text(loadingText(for: vm.state))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                    }
                                }
                                .padding()
                            }
                            .onChange(of: vm.messages.count) { _, _ in
                                if let lastMessage = vm.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView("Initializing...")
                }
                
                Divider()
                
                // Input area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit {
                            sendMessage()
                        }
                        .disabled((viewModel?.state ?? .idle) != .idle)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(messageText.isEmpty || (viewModel?.state ?? .idle) != .idle ? .gray : AppTheme.accent)
                    }
                    .disabled(messageText.isEmpty || (viewModel?.state ?? .idle) != .idle)
                    .accessibilityLabel("Send message")
                }
                .padding()
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("Assistant")
            .toolbarBackground(AppTheme.barBackground, for: .navigationBar)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let vm = viewModel, vm.state != .idle {
                        Button("Cancel") {
                            vm.state = .idle
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingConfirmation ?? false },
                set: { if !$0 { viewModel?.showingConfirmation = false } }
            )) {
                if let pending = viewModel?.pendingToolCall {
                    ToolConfirmationView(
                        toolName: pending.tool,
                        confirmationMessage: pending.confirmationMessage ?? "Are you sure you want to proceed?",
                        onConfirm: {
                            viewModel?.confirmToolCall()
                        },
                        onCancel: {
                            viewModel?.cancelToolCall()
                        }
                    )
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel?.showingError ?? false },
                set: { if !$0 { viewModel?.showingError = false } }
            )) {
                Button("OK", role: .cancel) { }
                Button("Retry") {
                    // Could implement retry logic here
                }
            } message: {
                Text(viewModel?.errorMessage ?? "An error occurred")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = services.makeAssistantViewModel()
            }
        }
    }
    
    private func loadingText(for state: AssistantViewModel.AssistantState) -> String {
        switch state {
        case .thinking:
            return "Thinking..."
        case .executingTool:
            return "Executing action..."
        case .waitingForConfirmation:
            return "Waiting for confirmation..."
        case .idle:
            return ""
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let vm = viewModel else { return }
        let text = messageText
        messageText = ""
        isInputFocused = false
        vm.sendUserMessage(text)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isUser ? AppTheme.accent : AppTheme.surfaceSecondary)
                    .foregroundStyle(isUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct ToolConfirmationView: View {
    let toolName: String
    let confirmationMessage: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.warning)
                
                Text("Confirm Action")
                    .font(.headline)
                
                Text(confirmationMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Text("Tool: \(toolName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Confirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm", action: onConfirm)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct EmptyAssistantView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            Text("AI Assistant")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Ask me to add items to your inventory, plan meals, generate grocery lists, or log dishes you've cooked")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI Assistant. Ask me to add items to your inventory, plan meals, generate grocery lists, or log dishes you've cooked")
    }
}

#Preview {
    let (modelContainer, services) = PreviewServices.previewContainer()
    return AssistantView()
        .modelContainer(modelContainer)
        .environmentObject(services)
}
