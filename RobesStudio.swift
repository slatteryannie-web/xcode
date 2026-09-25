import SwiftUI

// MARK: - Variation 3 · Studio
//
// Making comes first. Instead of browsing a catalogue and drilling into a
// detail screen, Studio puts one look on a stage and keeps its pieces as a row
// of chips underneath — tap a chip and the alternatives slide in, so swapping a
// piece never leaves the canvas. Navigation moves to a vertical rail on the
// left, which frees the whole width for the work.

struct RobesStudio: View {
    @State private var tab: StudioTab = .looks
    @State private var showProfile = false

    var body: some View {
        HStack(spacing: 0) {
            StudioRail(tab: $tab, showProfile: $showProfile)

            ZStack {
                RobesColor.paper

                switch tab {
                case .looks: StudioBench()
                case .items: StudioShelf()
                case .plan:  StudioWeek()
                }
            }
        }
        .background(RobesColor.paperLight)
        .sheet(isPresented: $showProfile) { StudioProfile() }
    }
}

enum StudioTab: String, CaseIterable {
    case looks = "Looks"
    case items = "Items"
    case plan = "Plan"

    var symbol: String {
        switch self {
        case .looks: "rectangle.stack"
        case .items: "hanger"
        case .plan: "calendar"
        }
    }
}

// MARK: - Vertical navigation rail

private struct StudioRail: View {
    @Binding var tab: StudioTab
    @Binding var showProfile: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("R")
                .font(RobesType.serif(20, .regular))
                .tracking(2)
                .foregroundStyle(RobesColor.ink)
                .padding(.top, 8)
                .padding(.bottom, 30)

            ForEach(StudioTab.allCases, id: \.self) { candidate in
                let isSelected = candidate == tab

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { tab = candidate }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: candidate.symbol)
                            .font(.system(size: 15, weight: .light))
                        MicroLabel(candidate.rawValue,
                                   color: isSelected ? RobesColor.ink : RobesColor.taupe,
                                   size: 7, tracking: 0.8)
                    }
                    .foregroundStyle(isSelected ? RobesColor.ink : RobesColor.taupe)
                    .frame(width: 58, height: 62)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 4).fill(RobesColor.paper)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
            }

            Spacer()

            Button {
                showProfile = true
            } label: {
                Text("A")
                    .font(RobesType.serif(13, .regular))
                    .foregroundStyle(RobesColor.umber)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(RobesColor.paper))
                    .overlay(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
            }
            .accessibilityLabel("Profile and settings")
            .padding(.bottom, 10)
        }
        .frame(width: 62)
        .background(RobesColor.paperLight)
        .overlay(alignment: .trailing) {
            Rectangle().fill(RobesColor.line).frame(width: 1)
        }
    }
}

// MARK: - The bench (Looks)

private struct StudioBench: View {
    /// The look currently on the stage, held as loose pieces so it can be edited in place.
    @State private var look = RobesSample.modernClassic
    @State private var pieces = RobesSample.modernClassic.pieces
    @State private var selection: Int? = nil
    @State private var asFlatLay = false
    @State private var prompt = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                StudioPromptBar(prompt: $prompt)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                // -- Stage ---------------------------------------------------
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            MicroLabel(look.isSuggested ? "On the stand · suggested" : "On the stand",
                                       color: RobesColor.taupe, size: 8)
                            Text(look.name)
                                .font(RobesType.serif(27, .light, italic: true))
                                .foregroundStyle(RobesColor.ink)
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { asFlatLay.toggle() }
                        } label: {
                            Text(asFlatLay ? "See on body" : "See as flat lay")
                                .font(RobesType.sans(11))
                                .underline()
                                .foregroundStyle(RobesColor.clay)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 22)

                    ZStack {
                        RadialGradient(
                            colors: [RobesColor.card, RobesColor.paperLight],
                            center: .center, startRadius: 10, endRadius: 260
                        )

                        if asFlatLay {
                            StudioFlatLay(pieces: pieces)
                        } else {
                            Image(look.asset)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.vertical, 10)
                        }
                    }
                    .frame(height: 340)
                    .clipped()
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(RobesColor.line, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.horizontal, 14)
                    .padding(.top, 14)

                    Text(look.note)
                        .font(RobesType.serif(15, .light))
                        .italic()
                        .foregroundStyle(RobesColor.umber)
                        .lineSpacing(4)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                }

                // -- The pieces, always in reach -----------------------------
                HStack {
                    MicroLabel("\(pieces.count) pieces", color: RobesColor.clay, size: 8)
                    Spacer()
                    if selection != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selection = nil }
                        } label: {
                            MicroLabel("Done", color: RobesColor.ink, size: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 26)
                .padding(.bottom, 9)

                ScrollView(.horizontal) {
                    HStack(spacing: 9) {
                        ForEach(Array(pieces.enumerated()), id: \.offset) { index, piece in
                            StudioPieceChip(piece: piece, isSelected: selection == index) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selection = selection == index ? nil : index
                                }
                            }
                        }

                        // Add another piece to the look
                        VStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(RobesColor.taupe)
                            MicroLabel("Add", color: RobesColor.taupe, size: 7, tracking: 0.8)
                        }
                        .frame(width: 68, height: 92)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                .foregroundStyle(RobesColor.line)
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .scrollIndicators(.hidden)

                // -- Swap tray -----------------------------------------------
                if let index = selection, pieces.indices.contains(index) {
                    StudioSwapTray(piece: pieces[index]) { replacement in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            pieces[index] = LookPiece(
                                item: replacement,
                                slot: pieces[index].slot,
                                rationale: pieces[index].rationale
                            )
                        }
                    }
                    .padding(.top, 16)
                }

                // -- Actions --------------------------------------------------
                HStack(spacing: 9) {
                    StudioButton(title: "Save look", filled: true)
                    StudioButton(title: "Wear today")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                        .foregroundStyle(RobesColor.ink)
                        .frame(width: 38, height: 38)
                        .background(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
                }
                .padding(.horizontal, 14)
                .padding(.top, 24)

                // -- Everything else you've made ------------------------------
                StudioShelfStrip(
                    title: "Your looks",
                    looks: RobesSample.savedLooks,
                    current: look
                ) { chosen in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        look = chosen
                        pieces = chosen.pieces
                        selection = nil
                        asFlatLay = false
                    }
                }
                .padding(.top, 34)

                StudioShelfStrip(
                    title: "Robes suggests",
                    looks: RobesSample.suggestedLooks,
                    current: look
                ) { chosen in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        look = chosen
                        pieces = chosen.pieces
                        selection = nil
                        asFlatLay = false
                    }
                }
                .padding(.top, 26)

                Spacer(minLength: 30)
            }
        }
        .scrollIndicators(.hidden)
    }
}

/// Every way in to a new look, collapsed into one bar.
private struct StudioPromptBar: View {
    @Binding var prompt: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(RobesColor.clay)

            TextField("Describe a look…", text: $prompt)
                .font(RobesType.sans(13))
                .foregroundStyle(RobesColor.ink)
                .textFieldStyle(.plain)

            Rectangle()
                .fill(RobesColor.line)
                .frame(width: 1, height: 18)

            ForEach(["camera", "photo.on.rectangle.angled", "link"], id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.system(size: 12))
                    .foregroundStyle(RobesColor.clay)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Capsule().fill(RobesColor.card))
        .overlay(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
    }
}

/// The pieces of a look, arranged loosely the way you'd lay them on a bed.
private struct StudioFlatLay: View {
    let pieces: [LookPiece]

    /// Hand-placed offsets and tilts so the arrangement reads as a real flat lay.
    private let placements: [(x: CGFloat, y: CGFloat, angle: Double, scale: CGFloat)] = [
        (-58, -74, -6, 1.00),
        (54, -50, 5, 0.94),
        (-64, 74, 7, 0.80),
        (60, 82, -8, 0.74)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(pieces.prefix(4).enumerated()), id: \.offset) { index, piece in
                let placement = placements[index % placements.count]

                Image(piece.item.asset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150 * placement.scale, height: 150 * placement.scale)
                    .rotationEffect(.degrees(placement.angle))
                    .offset(x: placement.x, y: placement.y)
            }
        }
    }
}

private struct StudioPieceChip: View {
    let piece: LookPiece
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack {
                    RobesColor.paperLight
                    Image(piece.item.asset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                }
                .frame(height: 64)

                MicroLabel(piece.item.role.badge,
                           color: isSelected ? RobesColor.paperLight : RobesColor.clay,
                           size: 6, tracking: 0.6)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(isSelected ? RobesColor.ink : RobesColor.card)
            }
            .frame(width: 68)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(isSelected ? RobesColor.ink : RobesColor.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(piece.item.name), \(piece.slot.rawValue)")
    }
}

/// Alternatives for the selected slot — owned pieces first, then suggestions.
private struct StudioSwapTray: View {
    let piece: LookPiece
    let onPick: (RobesItem) -> Void

    private var alternatives: [RobesItem] {
        let sameRole = RobesSample.allItems.filter {
            $0.role == piece.item.role && $0.id != piece.item.id
        }
        return sameRole.sorted { $0.owned && !$1.owned }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                MicroLabel("Swapping", color: RobesColor.taupe, size: 8)
                Text(piece.slot.rawValue)
                    .font(RobesType.serif(14, .regular, italic: true))
                    .foregroundStyle(RobesColor.ink)
                Spacer()
                MicroLabel("\(alternatives.count) options", color: RobesColor.taupe, size: 8)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            if alternatives.isEmpty {
                Text("Nothing else in this slot yet — capture a piece and it'll show up here.")
                    .font(RobesType.serif(14, .light))
                    .italic()
                    .foregroundStyle(RobesColor.taupe)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 9) {
                        ForEach(alternatives) { candidate in
                            Button {
                                onPick(candidate)
                            } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    ZStack(alignment: .topTrailing) {
                                        RobesColor.card
                                        Image(candidate.asset)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .padding(7)

                                        if !candidate.owned {
                                            Circle()
                                                .fill(RobesColor.blush)
                                                .frame(width: 7, height: 7)
                                                .padding(6)
                                        }
                                    }
                                    .frame(height: 76)

                                    Text(candidate.name)
                                        .font(RobesType.serif(12, .regular))
                                        .foregroundStyle(RobesColor.ink)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 7)
                                        .padding(.top, 6)

                                    Text(candidate.owned ? candidate.wearLabel : (candidate.price ?? "Suggested"))
                                        .font(RobesType.sans(9))
                                        .foregroundStyle(candidate.owned ? RobesColor.sage : RobesColor.clay)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 7)
                                        .padding(.bottom, 8)
                                }
                                .frame(width: 92, height: 146, alignment: .top)
                                .background(RobesColor.paperLight)
                                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.vertical, 14)
        .background(RobesColor.blush.opacity(0.25))
        .overlay(alignment: .top) { Rectangle().fill(RobesColor.line).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(RobesColor.line).frame(height: 1) }
    }
}

private struct StudioShelfStrip: View {
    let title: String
    let looks: [RobesLook]
    let current: RobesLook
    let onPick: (RobesLook) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            MicroLabel(title, color: RobesColor.clay, size: 8)
                .padding(.horizontal, 14)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(looks) { look in
                        let isCurrent = look.id == current.id

                        Button {
                            onPick(look)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(look.asset)
                                    .resizable()
                                    .aspectRatio(4.0 / 5.0, contentMode: .fill)
                                    .frame(width: 96, height: 120)
                                    .clipped()

                                Text(look.name)
                                    .font(RobesType.serif(14, .regular))
                                    .foregroundStyle(RobesColor.ink)
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.bottom, 7)
                            }
                            .frame(width: 96, alignment: .leading)
                            .background(RobesColor.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(isCurrent ? RobesColor.ink : RobesColor.line,
                                                  lineWidth: isCurrent ? 1.5 : 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - The shelf (Items)

private struct StudioShelf: View {
    @State private var role: ItemRole = .top

    private var items: [RobesItem] {
        RobesSample.allItems.filter { $0.role == role }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Add bar
                HStack(spacing: 0) {
                    ForEach(RobesCapture.items) { source in
                        HStack(spacing: 6) {
                            Image(systemName: source.symbol)
                                .font(.system(size: 11))
                            MicroLabel(source.title, color: RobesColor.ink, size: 8, tracking: 0.9)
                        }
                        .foregroundStyle(RobesColor.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(alignment: .trailing) {
                            if source.id != RobesCapture.items.last?.id {
                                Rectangle().fill(RobesColor.line).frame(width: 1, height: 20)
                            }
                        }
                    }
                }
                .background(RobesColor.card)
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 14)
                .padding(.top, 12)

                // Role selector, set as editorial words rather than chips
                ScrollView(.horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        ForEach(ItemRole.allCases, id: \.self) { candidate in
                            let isSelected = candidate == role

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { role = candidate }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(candidate.plural)
                                        .font(RobesType.serif(23, isSelected ? .regular : .light,
                                                              italic: isSelected))
                                        .foregroundStyle(isSelected ? RobesColor.ink : RobesColor.taupe)
                                    Rectangle()
                                        .fill(isSelected ? RobesColor.ink : .clear)
                                        .frame(height: 1)
                                }
                                .fixedSize()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 26)

                HStack(spacing: 5) {
                    MicroLabel("\(items.filter(\.owned).count) yours", color: RobesColor.sage, size: 8)
                    Text("·")
                        .font(RobesType.sans(8))
                        .foregroundStyle(RobesColor.taupe)
                    MicroLabel("\(items.filter { !$0.owned }.count) suggested",
                               color: RobesColor.taupe, size: 8)
                }
                .padding(.horizontal, 14)
                .padding(.top, 16)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        StudioItemCard(item: item)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                Spacer(minLength: 30)
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct StudioItemCard: View {
    let item: RobesItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RadialGradient(
                    colors: [RobesColor.card, RobesColor.paperLight],
                    center: .center, startRadius: 4, endRadius: 130
                )

                Image(item.asset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(14)

                if !item.owned {
                    MicroLabel("Suggested", color: RobesColor.umber, size: 6, tracking: 0.8)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(RobesColor.blush))
                        .padding(8)
                }
            }
            .frame(height: 156)
            .clipped()

            Text(item.name)
                .font(RobesType.serif(15, .regular))
                .foregroundStyle(RobesColor.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.top, 9)

            MicroLabel(item.brand, color: RobesColor.taupe, size: 7, tracking: 0.9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.top, 3)

            Text(item.owned ? item.wearLabel : (item.price ?? ""))
                .font(RobesType.sans(9))
                .foregroundStyle(item.owned ? RobesColor.sage : RobesColor.clay)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.top, 5)
                .padding(.bottom, 11)
        }
        .background(RobesColor.card)
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - The week (Plan)

private struct StudioWeek: View {
    @State private var week = RobesSample.week

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                MicroLabel("The week ahead", color: RobesColor.taupe, size: 8)
                Text(RobesSample.monthTitle)
                    .font(RobesType.serif(26, .light, italic: true))
                    .foregroundStyle(RobesColor.ink)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)

            // A rack of days — each day is a column you hang looks on.
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(week) { day in
                        StudioDayColumn(day: day)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 18)
            }
            .scrollIndicators(.hidden)

            Rectangle().fill(RobesColor.line).frame(height: 1)

            // Anything unassigned, ready to be dropped onto a day
            VStack(alignment: .leading, spacing: 9) {
                MicroLabel("Unplanned looks · drag onto a day", color: RobesColor.clay, size: 8)
                    .padding(.horizontal, 14)

                ScrollView(.horizontal) {
                    HStack(spacing: 9) {
                        ForEach(RobesSample.allLooks) { look in
                            HStack(spacing: 8) {
                                Image(look.asset)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 34, height: 42)
                                    .clipped()

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(look.name)
                                        .font(RobesType.serif(13, .regular))
                                        .foregroundStyle(RobesColor.ink)
                                        .lineLimit(1)
                                    MicroLabel("\(look.pieces.count) pieces",
                                               color: RobesColor.taupe, size: 6, tracking: 0.7)
                                }

                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RobesColor.line)
                            }
                            .padding(6)
                            .background(RobesColor.card)
                            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(RobesColor.line, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.vertical, 16)

            Spacer()
        }
    }
}

private struct StudioDayColumn: View {
    let day: PlanEntry

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 1) {
                MicroLabel(day.weekdayShort,
                           color: day.isToday ? RobesColor.paperLight : RobesColor.taupe,
                           size: 7, tracking: 0.9)
                Text(day.dayNumber)
                    .font(RobesType.serif(19, .light))
                    .foregroundStyle(day.isToday ? RobesColor.paperLight : RobesColor.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(day.isToday ? RobesColor.ink : RobesColor.paperLight)

            Rectangle().fill(RobesColor.line).frame(height: 1)

            VStack(spacing: 6) {
                Text(day.occasion ?? "")
                    .font(RobesType.serif(12, .light, italic: true))
                    .foregroundStyle(RobesColor.clay)
                    .lineLimit(1)
                    .frame(height: 15)

                ForEach(day.looks) { look in
                    Image(look.asset)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 92, height: 78)
                        .clipped()
                        .overlay(alignment: .bottom) {
                            Text(look.name)
                                .font(RobesType.serif(11, .regular))
                                .foregroundStyle(RobesColor.ink)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 3)
                                .frame(maxWidth: .infinity)
                                .background(RobesColor.card.opacity(0.94))
                        }
                }

                // Open slot — fills the column when the day is still empty
                VStack(spacing: 3) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .light))
                    MicroLabel("Add", color: RobesColor.taupe, size: 6, tracking: 0.7)
                }
                .foregroundStyle(RobesColor.taupe)
                .frame(width: 92)
                .frame(minHeight: 38, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(RobesColor.line)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        // A fixed height keeps the rack even, however many looks a day holds
        .frame(width: 108, height: 285)
        .background(RobesColor.card)
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Profile

private struct StudioProfile: View {
    @Environment(\.dismiss) private var dismiss
    @State private var useGenericModel = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    MicroLabel("Profile", color: RobesColor.taupe, size: 9)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RobesColor.clay)
                    }
                }
                .padding(.top, 22)

                Text("Anna")
                    .font(RobesType.serif(34, .light, italic: true))
                    .foregroundStyle(RobesColor.ink)
                    .padding(.top, 10)

                MicroLabel("Dublin · joined march 2026", color: RobesColor.taupe, size: 8)
                    .padding(.top, 3)

                // How looks get rendered on a body
                VStack(alignment: .leading, spacing: 12) {
                    MicroLabel("Your stand-in", color: RobesColor.clay, size: 8)

                    HStack(spacing: 10) {
                        StudioModelOption(
                            title: "Your selfie",
                            asset: RobesAsset.lookCasual,
                            isSelected: !useGenericModel
                        ) { useGenericModel = false }

                        StudioModelOption(
                            title: "Generic model",
                            asset: RobesAsset.lookDenim,
                            isSelected: useGenericModel
                        ) { useGenericModel = true }
                    }

                    Text("Looks are rendered on whichever stand-in you pick. Your selfie never leaves your device.")
                        .font(RobesType.serif(14, .light))
                        .italic()
                        .foregroundStyle(RobesColor.taupe)
                        .lineSpacing(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RobesColor.card)
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
                .padding(.top, 24)

                ForEach(["Auto-tagging", "Image clean-up", "Sharing & Instagram", "Notifications", "Privacy", "Sign out"], id: \.self) { row in
                    HStack {
                        Text(row)
                            .font(RobesType.sans(14))
                            .foregroundStyle(RobesColor.ink)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(RobesColor.taupe)
                    }
                    .padding(.vertical, 16)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(RobesColor.line).frame(height: 1)
                    }
                }
                .padding(.top, 22)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(RobesColor.paper.ignoresSafeArea())
    }
}

private struct StudioModelOption: View {
    let title: String
    let asset: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(asset)
                    .resizable()
                    .aspectRatio(4.0 / 5.0, contentMode: .fill)
                    .frame(height: 108)
                    .clipped()

                MicroLabel(title,
                           color: isSelected ? RobesColor.paperLight : RobesColor.clay,
                           size: 7, tracking: 0.9)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? RobesColor.ink : RobesColor.paperLight)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(isSelected ? RobesColor.ink : RobesColor.line,
                                  lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared pieces

private struct StudioButton: View {
    let title: String
    var filled: Bool = false

    var body: some View {
        Text(title.uppercased())
            .font(RobesType.sans(9, .medium))
            .tracking(1.1)
            .foregroundStyle(filled ? RobesColor.paperLight : RobesColor.ink)
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background {
                if filled {
                    Capsule().fill(RobesColor.ink)
                } else {
                    Capsule().strokeBorder(RobesColor.line, lineWidth: 1)
                }
            }
    }
}

// MARK: - Preview

#Preview("Studio — canvas & swap tray") {
    RobesStudio()
}
