import SwiftUI

struct FilterSheetView: View {
    @Bindable var viewModel: MainSwipeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var filterVM = FilterViewModel()

    private var backgroundColor: Color {
        TidyTheme.Colors.background(for: colorScheme)
    }

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Main filters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filters")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(textColor.opacity(0.5))
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(PhotoFilter.allCases) { filter in
                                FilterRow(
                                    title: filter.displayName,
                                    icon: filter.iconName,
                                    count: filterVM.count(for: filter),
                                    isSelected: viewModel.currentFilter == filter && viewModel.selectedYear == nil,
                                    action: {
                                        viewModel.applyFilter(filter)
                                        dismiss()
                                    }
                                )

                                if filter != PhotoFilter.allCases.last {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }

                    // Year filters
                    if !filterVM.availableYears.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Year")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundStyle(textColor.opacity(0.5))
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(filterVM.availableYears, id: \.self) { year in
                                    FilterRow(
                                        title: String(year),
                                        icon: "calendar",
                                        count: filterVM.count(for: year),
                                        isSelected: viewModel.selectedYear == year,
                                        action: {
                                            viewModel.applyFilter(.all, year: year)
                                            dismiss()
                                        }
                                    )

                                    if year != filterVM.availableYears.last {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                            .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Filter Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(TidyTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            filterVM.loadCounts()
        }
    }
}

// MARK: - Filter Row

private struct FilterRow: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        TidyTheme.Colors.text(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? TidyTheme.Colors.primary : textColor.opacity(0.6))
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? TidyTheme.Colors.primary : textColor)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 14))
                    .foregroundStyle(textColor.opacity(0.5))

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TidyTheme.Colors.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSheetView(viewModel: MainSwipeViewModel())
}
