import SwiftUI

// MARK: - Variation 1 · Atelier
//
// An editorial, magazine-led reading of Robes. Looks arrive as full-bleed
// vertical spreads you scroll through like a lookbook; the on-body render is
// the hero and every card can be flipped to show the pieces it is built from.
// Chrome is custom and deliberately quiet: a serif wordmark above, a hairline
// tab rule below.

struct RobesAtelier: View {
    @State private var tab: AtelierTab = .looks
    @State private var showProfile = false

    var body: some View {
        ZStack(alignment: .bottom) {
            RobesColor.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                AtelierTopBar(showProfile: $showProfile)

                ScrollView {
                    switch tab {
                    case .looks: AtelierLooks()
                    case .items: AtelierItems()
                    case .plan:  AtelierPlan()
                    }
                }
                .scrollIndicators(.hidden)
            }

            AtelierTabBar(selection: $tab)
        }
        .sheet(isPresented: $showProfile) {
            AtelierProfile()
        }
    }
}

enum AtelierTab: String, CaseIterable {
    case looks = "Looks"
    case items = "Items"
    case plan = "Plan"
}

// MARK: - Chrome

private struct AtelierTopBar: View {
    @Binding var showProfile: Bool

    var body: some View {
        HStack(alignment: .center) {
            Wordmark(size: 16)

            Spacer()

            MicroLabel(RobesSample.weatherLine, color: RobesColor.taupe, size: 9, tracking: 1.1)

            Button {
                showProfile = true
            } label: {
                Text("A")
                    .font(RobesType.serif(14, .regular))
                    .foregroundStyle(RobesColor.umber)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(RobesColor.paperLight))
                    .overlay(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
            }
            .accessibilityLabel("Profile and settings")
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 14)
        .background(RobesColor.paper)
        .overlay(alignment: .bottom) {
            Rectangle().fill(RobesColor.line).frame(height: 1)
        }
    }
}

private struct AtelierTabBar: View {
    @Binding var selection: AtelierTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AtelierTab.allCases, id: \.self) { tab in
                let isSelected = tab == selection

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = tab }
                } label: {
                    VStack(spacing: 7) {
                        Text(tab.rawValue)
                            .font(RobesType.serif(19, isSelected ? .regular : .light, italic: isSelected))
                            .foregroundStyle(isSelected ? RobesColor.ink : RobesColor.taupe)

                        Rectangle()
                            .fill(isSelected ? RobesColor.ink : .clear)
                            .frame(width: 22, height: 1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
        .background {
            RobesColor.paperLight
                .overlay(alignment: .top) {
                    Rectangle().fill(RobesColor.line).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Looks

private struct AtelierLooks: View {
    @State private var showingSuggested = false

    private var looks: [RobesLook] {
        showingSuggested ? RobesSample.suggestedLooks : RobesSample.savedLooks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AtelierSectionHead(
                label: "Lookbook",
                title: "Everything you've worn,",
                subtitle: "and everything you might."
            )

            AtelierCaptureRail(sources: RobesCapture.looks)
                .padding(.top, 26)

            AtelierSwitch(
                left: "Saved",
                right: "Suggested",
                isRight: $showingSuggested
            )
            .padding(.horizontal, 22)
            .padding(.top, 34)

            LazyVStack(spacing: 46) {
                ForEach(looks) { look in
                    AtelierLookSpread(look: look)
                }
            }
            .padding(.top, 26)

            Spacer(minLength: 120)
        }
    }
}

/// A full-bleed editorial spread for one look.
private struct AtelierLookSpread: View {
    let look: RobesLook
    @State private var showingPieces = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // -- The render, or the pieces behind it ------------------------
            ZStack(alignment: .topLeading) {
                if showingPieces {
                    AtelierPieceMosaic(pieces: look.pieces)
                } else {
                    Image(look.asset)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 460)
                        .clipped()
                }

                if !showingPieces {
                    HStack(spacing: 6) {
                        Image(systemName: look.origin.symbol)
                            .font(.system(size: 8, weight: .medium))
                        MicroLabel(look.origin.label, color: RobesColor.umber, size: 8, tracking: 1.2)
                    }
                    .foregroundStyle(RobesColor.umber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(RobesColor.paperLight.opacity(0.92)))
                    .padding(16)
                }
            }
            .frame(height: 460)
            .overlay(alignment: .bottomTrailing) {
                AtelierViewToggle(showingPieces: $showingPieces)
                    .padding(16)
            }

            // -- The editorial block --------------------------------------
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    MicroLabel(look.isSuggested ? "Suggested look" : "Saved look",
                               color: RobesColor.taupe, size: 9)
                    Text("·")
                        .font(RobesType.sans(9))
                        .foregroundStyle(RobesColor.taupe)
                    MicroLabel("\(look.pieces.count) pieces", color: RobesColor.taupe, size: 9)
                }
                .padding(.top, 20)

                Text(look.name)
                    .font(RobesType.serif(34, .light, italic: true))
                    .foregroundStyle(RobesColor.ink)
                    .padding(.top, 6)

                Text(look.note)
                    .font(RobesType.serif(17, .light))
                    .italic()
                    .foregroundStyle(RobesColor.umber)
                    .lineSpacing(5)
                    .padding(.top, 10)

                if !look.isWearable {
                    AtelierWishlistNote()
                        .padding(.top, 16)
                }

                // Auto-applied tags
                HStack(spacing: 6) {
                    ForEach(look.tags, id: \.self) { tag in
                        Text(tag)
                            .font(RobesType.sans(11))
                            .foregroundStyle(RobesColor.umber)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(RobesColor.paperLight))
                            .overlay(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
                    }

                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(RobesColor.taupe)
                        .frame(width: 24, height: 24)
                        .background(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
                }
                .padding(.top, 18)

                Rectangle()
                    .fill(RobesColor.line)
                    .frame(height: 1)
                    .padding(.top, 20)

                // Actions
                HStack(spacing: 10) {
                    AtelierAction(title: look.isWearable ? "Wear today" : "Plan it",
                                  symbol: "calendar", filled: true)
                    AtelierAction(title: "Edit", symbol: "slider.horizontal.3")
                    Spacer()
                    AtelierAction(title: nil, symbol: "square.and.arrow.up")
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 22)
        }
    }
}

/// A look shown as the collection of pieces it is made from.
private struct AtelierPieceMosaic: View {
    let pieces: [LookPiece]

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 1), GridItem(.flexible(), spacing: 1)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(pieces.prefix(4)) { piece in
                ZStack(alignment: .topLeading) {
                    RobesColor.paperLight
                    Image(piece.item.asset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(14)

                    MicroLabel(piece.item.role.badge, color: RobesColor.clay, size: 7, tracking: 1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(RobesColor.card.opacity(0.9)))
                        .padding(8)
                }
                .frame(height: 229)
                .clipped()
            }
        }
        .background(RobesColor.line)
    }
}

private struct AtelierViewToggle: View {
    @Binding var showingPieces: Bool

    var body: some View {
        HStack(spacing: 0) {
            toggle(symbol: "figure.stand", active: !showingPieces) { showingPieces = false }
            toggle(symbol: "square.grid.2x2", active: showingPieces) { showingPieces = true }
        }
        .background(Capsule().fill(RobesColor.paperLight.opacity(0.92)))
        .overlay(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
    }

    private func toggle(symbol: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(active ? RobesColor.card : RobesColor.clay)
                .frame(width: 38, height: 30)
                .background {
                    if active {
                        Capsule().fill(RobesColor.ink)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "figure.stand" ? "View on body" : "View as pieces")
    }
}

private struct AtelierWishlistNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bookmark")
                .font(.system(size: 10))
                .foregroundStyle(RobesColor.clay)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                MicroLabel("Not yours yet", color: RobesColor.umber, size: 9)
                Text("Robes proposed this before the pieces were in your wardrobe. They're saved to your wishlist.")
                    .font(RobesType.sans(12))
                    .foregroundStyle(RobesColor.clay)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 4).fill(RobesColor.blush.opacity(0.35)))
    }
}

private struct AtelierAction: View {
    let title: String?
    let symbol: String
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .medium))
            if let title {
                Text(title.uppercased())
                    .font(RobesType.sans(10, .medium))
                    .tracking(1.2)
            }
        }
        .foregroundStyle(filled ? RobesColor.paperLight : RobesColor.ink)
        .padding(.horizontal, title == nil ? 12 : 16)
        .padding(.vertical, 11)
        .background {
            if filled {
                Capsule().fill(RobesColor.ink)
            } else {
                Capsule().strokeBorder(RobesColor.line, lineWidth: 1)
            }
        }
    }
}

// MARK: - Items

private struct AtelierItems: View {
    @State private var role: ItemRole? = nil

    private var items: [RobesItem] {
        guard let role else { return RobesSample.ownedItems }
        return RobesSample.ownedItems(role: role)
    }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AtelierSectionHead(
                label: "The wardrobe",
                title: "\(RobesSample.ownedItems.count) pieces,",
                subtitle: "cleaned up and catalogued."
            )

            AtelierCaptureRail(sources: RobesCapture.items)
                .padding(.top, 26)

            // Role filter
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    AtelierFilterChip(title: "All", active: role == nil) { role = nil }
                    ForEach(ItemRole.allCases, id: \.self) { candidate in
                        AtelierFilterChip(title: candidate.plural, active: role == candidate) {
                            role = role == candidate ? nil : candidate
                        }
                    }
                }
                .padding(.horizontal, 22)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 30)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(items) { item in
                    AtelierItemCard(item: item)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)

            // Suggestions
            HStack {
                MicroLabel("Suggested for you", color: RobesColor.clay)
                Spacer()
                MicroLabel("Search items", color: RobesColor.taupe, size: 9)
            }
            .padding(.horizontal, 22)
            .padding(.top, 44)
            .padding(.bottom, 14)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(RobesSample.suggestedItems) { item in
                        AtelierItemCard(item: item)
                            .frame(width: 150)
                    }
                }
                .padding(.horizontal, 22)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 120)
        }
    }
}

private struct AtelierItemCard: View {
    let item: RobesItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RobesColor.paperLight
                Image(item.asset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)

                if !item.owned {
                    MicroLabel("Suggested", color: RobesColor.umber, size: 7, tracking: 1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(RobesColor.blush))
                        .padding(8)
                }
            }
            .frame(height: 168)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(RobesType.serif(16, .regular))
                    .foregroundStyle(RobesColor.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                MicroLabel(item.brand, color: RobesColor.taupe, size: 8, tracking: 1.1)

                Spacer(minLength: 6)

                if item.owned {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                        MicroLabel(item.wearLabel, color: RobesColor.sage, size: 8, tracking: 1)
                    }
                    .foregroundStyle(RobesColor.sage)
                } else {
                    Text([item.price, item.retailer].compactMap { $0 }.joined(separator: " · "))
                        .font(RobesType.sans(10))
                        .foregroundStyle(RobesColor.clay)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        }
        .background(RobesColor.card)
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(RobesColor.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Plan

private struct AtelierPlan: View {
    @State private var week = RobesSample.week

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AtelierSectionHead(
                label: "The week",
                title: RobesSample.monthTitle + ",",
                subtitle: "dressed in advance."
            )

            // Day strip
            HStack(spacing: 6) {
                ForEach(week) { day in
                    VStack(spacing: 6) {
                        MicroLabel(day.weekdayInitial, color: day.isToday ? RobesColor.ink : RobesColor.taupe, size: 9)
                        Text(day.dayNumber)
                            .font(RobesType.serif(17, .light))
                            .foregroundStyle(day.isToday ? RobesColor.ink : RobesColor.clay)
                        Circle()
                            .fill(day.looks.isEmpty ? Color.clear : RobesColor.sage)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if day.isToday {
                            RoundedRectangle(cornerRadius: 3).fill(RobesColor.blush.opacity(0.45))
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)

            // Day-by-day
            VStack(spacing: 0) {
                ForEach(week) { day in
                    AtelierPlanRow(day: day)
                }
            }
            .padding(.top, 26)

            Spacer(minLength: 120)
        }
    }
}

private struct AtelierPlanRow: View {
    let day: PlanEntry

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                MicroLabel(day.weekdayShort, color: day.isToday ? RobesColor.ink : RobesColor.taupe, size: 9)
                Text(day.dayNumber)
                    .font(RobesType.serif(26, .light))
                    .foregroundStyle(day.isToday ? RobesColor.ink : RobesColor.clay)
            }
            .frame(width: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                if let occasion = day.occasion {
                    Text(occasion)
                        .font(RobesType.serif(15, .light, italic: true))
                        .foregroundStyle(RobesColor.umber)
                }

                if day.looks.isEmpty {
                    HStack(spacing: 7) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .medium))
                        MicroLabel("Assign a look", color: RobesColor.taupe, size: 9)
                    }
                    .foregroundStyle(RobesColor.taupe)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .foregroundStyle(RobesColor.line)
                    }
                } else {
                    ForEach(day.looks) { look in
                        HStack(spacing: 12) {
                            Image(look.asset)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 52, height: 66)
                                .clipped()

                            VStack(alignment: .leading, spacing: 3) {
                                Text(look.name)
                                    .font(RobesType.serif(18, .light))
                                    .foregroundStyle(RobesColor.ink)
                                MicroLabel("\(look.pieces.count) pieces", color: RobesColor.taupe, size: 8)
                            }

                            Spacer()

                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 11))
                                .foregroundStyle(RobesColor.line)
                        }
                        .padding(8)
                        .background(RobesColor.card)
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(RobesColor.line, lineWidth: 1))
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RobesColor.line)
                .frame(height: 1)
                .padding(.leading, 22)
        }
    }
}

// MARK: - Profile

private struct AtelierProfile: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Wordmark(size: 13)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RobesColor.clay)
                    }
                }
                .padding(.top, 24)

                Text("A")
                    .font(RobesType.serif(30, .light))
                    .foregroundStyle(RobesColor.umber)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(RobesColor.paperLight))
                    .overlay(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
                    .padding(.top, 28)

                Text("Anna")
                    .font(RobesType.serif(32, .light, italic: true))
                    .foregroundStyle(RobesColor.ink)
                    .padding(.top, 14)

                MicroLabel("Dublin · joined march 2026", color: RobesColor.taupe, size: 9)
                    .padding(.top, 4)

                HStack(spacing: 0) {
                    AtelierStat(value: "\(RobesSample.ownedItems.count)", label: "Pieces")
                    AtelierStat(value: "\(RobesSample.allLooks.count)", label: "Looks")
                    AtelierStat(value: "38", label: "Wears")
                }
                .padding(.top, 30)

                ForEach(["Your model", "Auto-tagging", "Image clean-up", "Sharing & Instagram", "Notifications", "Privacy", "Sign out"], id: \.self) { row in
                    HStack {
                        Text(row)
                            .font(RobesType.sans(14))
                            .foregroundStyle(RobesColor.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(RobesColor.taupe)
                    }
                    .padding(.vertical, 17)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(RobesColor.line).frame(height: 1)
                    }
                }
                .padding(.top, 24)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(RobesColor.paper.ignoresSafeArea())
    }
}

private struct AtelierStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(RobesType.serif(24, .light))
                .foregroundStyle(RobesColor.ink)
            MicroLabel(label, color: RobesColor.taupe, size: 8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared pieces

private struct AtelierSectionHead: View {
    let label: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MicroLabel(label, color: RobesColor.taupe, size: 9)
                .padding(.bottom, 12)

            Text(title)
                .font(RobesType.serif(32, .light))
                .foregroundStyle(RobesColor.ink)
            Text(subtitle)
                .font(RobesType.serif(32, .light, italic: true))
                .foregroundStyle(RobesColor.clay)
        }
        .padding(.horizontal, 22)
        .padding(.top, 28)
    }
}

/// Horizontal rail of ways to capture something new.
private struct AtelierCaptureRail: View {
    let sources: [CaptureSource]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(sources) { source in
                    VStack(alignment: .leading, spacing: 0) {
                        Image(systemName: source.symbol)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(RobesColor.ink)

                        Spacer(minLength: 18)

                        Text(source.title)
                            .font(RobesType.serif(17, .regular))
                            .foregroundStyle(RobesColor.ink)
                            .lineLimit(1)

                        Text(source.subtitle)
                            .font(RobesType.sans(10))
                            .foregroundStyle(RobesColor.taupe)
                            .lineLimit(2, reservesSpace: true)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                    }
                    .padding(14)
                    .frame(width: 142, height: 132, alignment: .topLeading)
                    .background(RobesColor.card)
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(RobesColor.line, lineWidth: 1))
                }
            }
            .padding(.horizontal, 22)
        }
        .scrollIndicators(.hidden)
    }
}

private struct AtelierSwitch: View {
    let left: String
    let right: String
    @Binding var isRight: Bool

    var body: some View {
        HStack(spacing: 0) {
            option(left, active: !isRight) { isRight = false }
            option(right, active: isRight) { isRight = true }
        }
        .padding(3)
        .background(Capsule().fill(RobesColor.paperLight))
        .overlay(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
    }

    private func option(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MicroLabel(title, color: active ? RobesColor.paperLight : RobesColor.clay, size: 10)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if active { Capsule().fill(RobesColor.ink) }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct AtelierFilterChip: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MicroLabel(title, color: active ? RobesColor.paperLight : RobesColor.clay, size: 9)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    if active {
                        Capsule().fill(RobesColor.ink)
                    } else {
                        Capsule().fill(RobesColor.card)
                            .overlay(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Atelier — editorial feed") {
    RobesAtelier()
}
