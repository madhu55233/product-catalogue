import SwiftUI

extension EnvironmentValues {
    @Entry var enquiryService: any EnquiryService = UnavailableEnquiryService()
}

struct EnquiryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EnquiryViewModel
    @State private var submissionAttempt = 0
    @FocusState private var focusedField: EnquiryViewModel.Field?

    init(product: Product, service: any EnquiryService) {
        _viewModel = State(initialValue: EnquiryViewModel(product: product, service: service))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.state == .sent {
                ContentUnavailableView {
                    Label("Thank you", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(CatalogueTheme.accent)
                } description: {
                    Text("Your enquiry about \(viewModel.product.title) has been sent to our sales team.")
                } actions: {
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("enquiry-done")
                }
                .accessibilityIdentifier("enquiry-thank-you")
            } else {
                enquiryForm
            }
        }
        .background(CatalogueTheme.background)
        .tint(CatalogueTheme.accent)
        .navigationTitle("Product enquiry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.state != .sent {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isSubmitting)
                        .accessibilityIdentifier("enquiry-cancel")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isSubmitting)
        .task(id: submissionAttempt) {
            guard submissionAttempt > 0 else { return }
            await viewModel.submit()
        }
    }

    private var enquiryForm: some View {
        Form {
            Section("Product") {
                Label(viewModel.product.title, systemImage: CatalogueCategoryStyle(category: viewModel.product.category).symbol)
                    .font(.headline)
                    .accessibilityIdentifier("enquiry-product")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name (required)").font(.subheadline.weight(.medium))
                    TextField("Full name", text: $viewModel.name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .accessibilityLabel("Name, required")
                        .accessibilityIdentifier("enquiry-name")
                    validationError(for: .name)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email (required)").font(.subheadline.weight(.medium))
                    TextField("name@example.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .accessibilityLabel("Email, required")
                        .accessibilityIdentifier("enquiry-email")
                    validationError(for: .email)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone (optional)").font(.subheadline.weight(.medium))
                    TextField("Phone number", text: $viewModel.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .phone)
                        .accessibilityLabel("Phone, optional")
                        .accessibilityIdentifier("enquiry-phone")
                    validationError(for: .phone)
                }
            } header: {
                Text("Contact details")
            } footer: {
                Text("Your contact details and message will be shared with our sales team to respond to this enquiry.")
            }

            Section("Message (optional)") {
                TextField("How can we help?", text: $viewModel.message, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: .message)
                    .accessibilityLabel("Message, optional")
                    .accessibilityIdentifier("enquiry-message")
                validationError(for: .message)
            }

            if case let .failed(message) = viewModel.state {
                Section {
                    Label("Submission not confirmed", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Text(message)
                        .accessibilityIdentifier("enquiry-submission-error")
                }
            }

            Section {
                Button {
                    focusedField = nil
                    submissionAttempt += 1
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSubmitting {
                            ProgressView()
                            Text("Sending…")
                        } else {
                            Label("Submit enquiry", systemImage: "paperplane.fill")
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .accessibilityIdentifier("enquiry-submit")
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .disabled(viewModel.isSubmitting)
    }

    @ViewBuilder
    private func validationError(for field: EnquiryViewModel.Field) -> some View {
        if let message = viewModel.validationMessage(for: field) {
            Label(message, systemImage: "exclamationmark.circle")
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
