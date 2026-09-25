import SwiftUI

// MARK: - Variation 2 · Rail
//
// The working tool. Where Atelier is a lookbook you read, Rail is a wardrobe
// you operate: native navigation, searchable catalogues, dense two-up grids and
// a look detail built around the photo — every piece listed under it, with the
// reason it's there and a way into the piece itself. Serif is rationed to names
// and numbers; everything structural is Inter.

struct RobesRail: View {
    @State private var showProfile = false

    var body: some View {
        TabView {
            RailLooksTab(showProfile: $showProfile)
                .tabItem { Label("Looks", systemImage: "square.stack") }

            RailItemsTab(showProfile: $showProfile)
                .tabItem { Label("Items", systemImage: "hanger") }

            RailPlanTab(showProfile: $showProfile)
                .tabItem { Label("Plan", systemImage: "calendar") }
        }
        .tint(RobesColor.ink)
        .sheet(isPresented: $showProfile) { RailProfile() }
    }
}

// MARK: - Looks

private struct RailLooksTab: View {
    @Binding var showProfile: Bool

    @State private var query = ""
    @State private var searching = false
    @State private var prompt = ""

    /// Searching cuts across every curation, so it replaces the rails with one
    /// flat grid of matches.
    private var results: [RobesLook] {
        RobesSample.allLooks.filter { $0.matches(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // One slot at the top of the tab: capture by default, search when
                    // it's asked for — two text fields never stack.
                    RailTopSlot(
                        searching: $searching,
                        query: $query,
                        prompt: $prompt,
                        searchPrompt: "Search looks and pieces",
                        capturePrompt: "Describe a look…",
                        captureSymbol: "sparkles",
                        sources: RobesCapture.looks
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    if query.isEmpty {
                        ForEach(LookCuration.allCases) { curation in
                            RailCurationRail(curation: curation)
                                .padding(.top, 24)
                        }

                        // Collections sit under the curations, and only once
                        // the wearer has made one.
                        if !RobesSample.collections.isEmpty {
                            RailCollectionsRail()
                                .padding(.top, 24)
                        }

                        Spacer(minLength: 34)
                    } else if results.isEmpty {
                        RailEmptyState(message: "No looks match that search.")
                            .padding(.top, 60)
                    } else {
                        RailLookGrid(items: results.map { RailGridItem(PlannedLook(look: $0)) })
                            .padding(16)
                    }
                }
            }
            .background(RobesColor.paper)
            .navigationTitle("Lookbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { Wordmark(size: 13) }
                ToolbarItem(placement: .topBarTrailing) {
                    RailSearchButton(searching: $searching)
                }
                ToolbarItem(placement: .topBarLeading) {
                    RailAvatarButton(showProfile: $showProfile)
                }
            }
        }
    }
}

/// One curation as a horizontal rail: tap a look to open it, or the heading to
/// see the whole curation as a grid.
private struct RailCurationRail: View {
    let curation: LookCuration

    /// How far a feed's rail runs before you have to tap through to the grid.
    private static let feedRailLength = 12

    private var entries: [PlannedLook] { curation.entries }

    private var items: [RailGridItem] {
        curation.isFeed
            ? RailGridItem.feed(entries, count: Self.feedRailLength)
            : RailGridItem.list(entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                RailCurationDetail(curation: curation)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(curation.title)
                        .font(RobesType.serif(20, .light))
                        .foregroundStyle(RobesColor.ink)

                    if curation.showsCount {
                        MicroLabel("\(entries.count)", color: RobesColor.taupe, size: 9)
                    }

                    Spacer(minLength: 8)

                    MicroLabel("See all", color: RobesColor.clay, size: 9)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(RobesColor.clay)
                }
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            if entries.isEmpty {
                RailEmptyState(message: "Nothing here yet.")
                    .padding(.vertical, 26)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink {
                                RailLookDetail(entry: item.entry)
                            } label: {
                                RailLookTile(entry: item.entry)
                                    .frame(width: 158)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 12)
            }
        }
    }
}

/// A whole curation, as a grid, with the tag filters that used to sit on the
/// Looks tab itself.
private struct RailCurationDetail: View {
    let curation: LookCuration

    @State private var activeTag: String? = nil
    @State private var pages = 1

    /// How many more the feed reaches for each time you hit the bottom, and the
    /// point at which it stops pretending — long past anyone's patience.
    private static let pageSize = 8
    private static let feedCeiling = 200

    private var entries: [PlannedLook] {
        guard let activeTag else { return curation.entries }
        return curation.entries.filter { $0.look.tags.contains(activeTag) }
    }

    /// A list curation shows exactly what it has. A feed keeps going: the
    /// sample set is finite, so it cycles to stand in for content that would
    /// stream from the server.
    private var items: [RailGridItem] {
        guard curation.isFeed else { return RailGridItem.list(entries) }
        return RailGridItem.feed(entries, count: min(pages * Self.pageSize, Self.feedCeiling))
    }

    /// Only the tags actually present in this curation are worth offering.
    private var tags: [String] {
        Array(Set(curation.entries.flatMap(\.look.tags))).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.horizontal) {
                    HStack(spacing: 7) {
                        ForEach(tags, id: \.self) { tag in
                            RailChip(title: tag, active: activeTag == tag) {
                                activeTag = activeTag == tag ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 12)

                if entries.isEmpty {
                    RailEmptyState(message: "No looks match that filter.")
                        .padding(.top, 60)
                } else {
                    RailLookGrid(items: items) {
                        guard curation.isFeed else { return }
                        pages += 1
                    }
                    .padding(16)
                }
            }
        }
        .background(RobesColor.paper)
        .navigationTitle(curation.title)
        .navigationBarTitleDisplayMode(.inline)
        // Narrowing the feed starts it over rather than leaving it as long as
        // the unfiltered scroll had made it.
        .onChange(of: activeTag) { pages = 1 }
    }
}

/// A grid cell. The identity carries a position so a feed can show the same
/// look again further down without two rows claiming the same id.
private struct RailGridItem: Identifiable {
    let entry: PlannedLook
    let id: String

    init(_ entry: PlannedLook, position: Int? = nil) {
        self.entry = entry
        self.id = position.map { "\(entry.id)#\($0)" } ?? entry.id
    }

    /// Exactly what the curation holds.
    static func list(_ entries: [PlannedLook]) -> [RailGridItem] {
        entries.map { RailGridItem($0) }
    }

    /// `count` cells drawn from `entries`, cycling when a feed asks for more
    /// than the sample set holds. Real feeds would page in fresh looks here.
    static func feed(_ entries: [PlannedLook], count: Int) -> [RailGridItem] {
        guard !entries.isEmpty else { return [] }
        return (0..<count).map { RailGridItem(entries[$0 % entries.count], position: $0) }
    }
}

/// The two-up grid of look tiles, shared by search results and curations.
private struct RailLookGrid: View {
    let items: [RailGridItem]
    /// Called when the last tile comes into view, so a feed can reach for more.
    var onReachEnd: (() -> Void)? = nil

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items) { item in
                NavigationLink {
                    RailLookDetail(entry: item.entry)
                } label: {
                    RailLookTile(entry: item.entry)
                }
                .buttonStyle(.plain)
                .onAppear {
                    if item.id == items.last?.id { onReachEnd?() }
                }
            }
        }
    }
}

/// Saved or still a suggestion. The distinction has to read at a glance
/// wherever looks are shown together, so every surface uses this one badge.
///
/// Over a photo there's no room for words, so tiles ask for `compact` and get
/// the icon alone; detail views spell it out.
private struct RailLookBadge: View {
    let look: RobesLook
    var size: CGFloat = 7
    var compact: Bool = false

    private var badge: LookBadge { look.badge }

    /// Three weights of ground: solid ink for something kept, pale for a
    /// proposal of Robes' own, mid-tone umber for one that came from a person.
    private var fill: Color {
        switch badge {
        case .saved: RobesColor.ink.opacity(0.88)
        case .suggestion: RobesColor.paperLight.opacity(0.94)
        case .shared: RobesColor.umber.opacity(0.92)
        }
    }

    private var foreground: Color {
        badge == .suggestion ? RobesColor.umber : RobesColor.paperLight
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: badge.symbol)
                .font(.system(size: size))
            if !compact {
                Text(badge.label.uppercased())
                    .font(RobesType.sans(size, .medium))
                    .tracking(0.9)
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, compact ? 5 : 6)
        .padding(.vertical, compact ? 4 : 3)
        .background(Capsule().fill(fill))
        .accessibilityLabel(badge.label)
    }
}

/// What the wearer doesn't own yet, marked with a heart on blush. A look carries
/// the number of its pieces that aren't theirs; a single piece carries the heart
/// alone, since there's nothing to count. Silent when they own it all.
///
/// The heart is the whole vocabulary — the word "wishlist" alongside it was
/// saying the same thing twice.
private struct RailWishlistBadge: View {
    /// Nil for a single piece.
    private let count: Int?
    private let size: CGFloat

    init(look: RobesLook, size: CGFloat = 7) {
        self.count = look.wishlistCount
        self.size = size
    }

    init(size: CGFloat = 7) {
        self.count = nil
        self.size = size
    }

    private var label: String {
        if let count { "\(count) on your wishlist" } else { "On your wishlist" }
    }

    var body: some View {
        if count != 0 {
            HStack(spacing: 3) {
                // Filled, because at this size a lone outline heart barely reads.
                Image(systemName: count == nil ? "heart.fill" : "heart")
                    .font(.system(size: size))

                if let count {
                    Text("\(count)")
                        .font(RobesType.sans(size, .medium))
                        .tracking(0.9)
                }
            }
            .foregroundStyle(RobesColor.umber)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(Capsule().fill(RobesColor.blush.opacity(0.95)))
            .accessibilityLabel(label)
        }
    }
}

private struct RailLookTile: View {
    let entry: PlannedLook

    private var look: RobesLook { entry.look }

    /// A look Robes is proposing for a day the wearer hasn't filled. Drawn as
    /// an outline rather than a solid card, so it reads as not-yet-committed.
    private var isProposal: Bool { entry.date != nil && !entry.isScheduled }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(look.asset)
                .resizable()
                .aspectRatio(4.0 / 5.0, contentMode: .fill)
                // Opposite corners, icon only: over a photo there isn't room
                // for two worded badges without covering the look.
                .overlay(alignment: .topLeading) {
                    RailLookBadge(look: look, compact: true).padding(7)
                }
                .overlay(alignment: .bottomTrailing) {
                    RailWishlistBadge(look: look).padding(7)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(look.name)
                    .font(RobesType.serif(15, .regular))
                    .foregroundStyle(RobesColor.ink)
                    .lineLimit(1)

                if let author = look.author {
                    MicroLabel("by \(author)", color: RobesColor.clay, size: 8, tracking: 1)
                        .lineLimit(1)
                }

                // The day gets its own line so it never wraps against the piece
                // count. A calendar icon marks the days actually assigned in the
                // plan, separating them from what Robes is proposing.
                if let dateLabel = entry.dateLabel {
                    HStack(spacing: 3) {
                        if entry.isScheduled {
                            Image(systemName: "calendar")
                                .font(.system(size: 8))
                                .foregroundStyle(RobesColor.ink)
                        }
                        MicroLabel(dateLabel,
                                   color: entry.isScheduled ? RobesColor.ink : RobesColor.clay,
                                   size: 8, tracking: 1)
                    }
                    .lineLimit(1)
                }

                HStack(spacing: 5) {
                    MicroLabel("\(look.pieces.count) pieces", color: RobesColor.taupe, size: 8, tracking: 1)
                    if look.wears > 0 {
                        RailDot()
                        MicroLabel(look.wearLabelShort, color: RobesColor.sage, size: 8, tracking: 1)
                    }
                }
                .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(isProposal ? Color.clear : RobesColor.card)
        .overlay {
            if isProposal {
                // Taupe at 1.5pt with a longer dash — the pale hairline used on
                // solid cards all but disappears against the paper.
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        RobesColor.taupe,
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(RobesColor.line, lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

private struct RailDot: View {
    var body: some View {
        Text("·")
            .font(RobesType.sans(8))
            .foregroundStyle(RobesColor.taupe)
    }
}

private extension RobesLook {
    var wearLabelShort: String { wears == 1 ? "1 wear" : "\(wears) wears" }

    func matches(_ query: String) -> Bool {
        name.localizedCaseInsensitiveContains(query)
            || tags.contains { $0.localizedCaseInsensitiveContains(query) }
            || items.contains { $0.name.localizedCaseInsensitiveContains(query) }
            || (author?.localizedCaseInsensitiveContains(query) ?? false)
    }
}

// MARK: - Collections

/// A collection has no photo of its own, so it's pictured by what's inside it:
/// up to four members, tiled. Looks fill their cell, pieces sit on the pale
/// ground they're shot against.
private struct RailCollectionCollage: View {
    let collection: RobesCollection

    private var members: [CollectionMember] { collection.collageMembers }

    var body: some View {
        Group {
            switch members.count {
            case 0:
                RobesColor.paperLight
            case 1:
                cell(members[0])
            case 2:
                HStack(spacing: 1) { cell(members[0]); cell(members[1]) }
            case 3:
                HStack(spacing: 1) {
                    cell(members[0])
                    VStack(spacing: 1) { cell(members[1]); cell(members[2]) }
                }
            default:
                HStack(spacing: 1) {
                    VStack(spacing: 1) { cell(members[0]); cell(members[2]) }
                    VStack(spacing: 1) { cell(members[1]); cell(members[3]) }
                }
            }
        }
        // Shows through the 1pt gutters as hairlines between the cells.
        .background(RobesColor.line)
    }

    /// The ground is a plain `Color` and the photo rides on it as an overlay.
    /// A stacked image would drive the cell's ideal size and the stacks would
    /// hand out uneven shares; a `Color` is purely flexible, so every cell gets
    /// the same slice whatever it holds.
    private func cell(_ member: CollectionMember) -> some View {
        RobesColor.paperLight
            .overlay {
                switch member {
                case .look(let look):
                    Image(look.asset)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .item(let item):
                    Image(item.asset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                }
            }
            .clipped()
    }
}

private struct RailCollectionTile: View {
    let collection: RobesCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // No collection-level wishlist tally: the badges on the individual
            // looks and pieces inside carry that.
            RailCollectionCollage(collection: collection)
                .aspectRatio(4.0 / 5.0, contentMode: .fit)
                .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(collection.name)
                    .font(RobesType.serif(15, .regular))
                    .foregroundStyle(RobesColor.ink)
                    .lineLimit(1)

                MicroLabel(collection.summary, color: RobesColor.taupe, size: 8, tracking: 1)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(RobesColor.card)
        .overlay {
            RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// The way into making one, drawn as an outline so it reads as a slot rather
/// than a collection that already exists.
private struct RailNewCollectionTile: View {
    /// Mirrors a real tile: a 4:5 collage area over a caption block, so the
    /// outline ends up the same height whatever width it's given.
    private static let captionHeight: CGFloat = 54

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .aspectRatio(4.0 / 5.0, contentMode: .fit)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .light))
                        MicroLabel("New collection", color: RobesColor.clay, size: 9)
                    }
                    .foregroundStyle(RobesColor.clay)
                }

            Color.clear.frame(height: Self.captionHeight)
        }
        .background {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(RobesColor.taupe, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        }
    }
}

/// Sits under the curations on the Looks tab, and only when there's something
/// to show.
private struct RailCollectionsRail: View {
    private var collections: [RobesCollection] { RobesSample.collections }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                RailCollectionsIndex()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text("Collections")
                        .font(RobesType.serif(20, .light))
                        .foregroundStyle(RobesColor.ink)

                    MicroLabel("\(collections.count)", color: RobesColor.taupe, size: 9)

                    Spacer(minLength: 8)

                    MicroLabel("See all", color: RobesColor.clay, size: 9)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(RobesColor.clay)
                }
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(collections) { collection in
                        NavigationLink {
                            RailCollectionDetail(collection: collection)
                        } label: {
                            RailCollectionTile(collection: collection)
                                .frame(width: 158)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        // Making a collection would start here.
                    } label: {
                        RailNewCollectionTile()
                            .frame(width: 158)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 12)
        }
    }
}

/// Every collection, as a grid.
private struct RailCollectionsIndex: View {
    private var collections: [RobesCollection] { RobesSample.collections }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(collections) { collection in
                    NavigationLink {
                        RailCollectionDetail(collection: collection)
                    } label: {
                        RailCollectionTile(collection: collection)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    // Making a collection would start here.
                } label: {
                    RailNewCollectionTile()
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(RobesColor.paper)
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One stop on the collection's filter strip: "All Items", or one of its looks.
/// Selected state is carried by the border and the dimming, so the strip reads
/// as a control rather than a row of links.
private struct RailCollectionFilterTile: View {
    let title: String
    /// Nil for the "All Items" stop, which has no photo of its own.
    let asset: String?
    let count: Int
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                RobesColor.paperLight
                    .overlay {
                        if let asset {
                            Image(asset)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 17, weight: .light))
                                .foregroundStyle(RobesColor.clay)
                        }
                    }
                    .frame(height: 96)
                    .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(RobesType.serif(13, .regular))
                        .foregroundStyle(RobesColor.ink)
                        .lineLimit(1)

                    MicroLabel("\(count) \(count == 1 ? "piece" : "pieces")",
                               color: RobesColor.taupe, size: 7, tracking: 1)
                        .lineLimit(1)
                }
                .padding(7)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 92)
            .background(RobesColor.card)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(selected ? RobesColor.ink : RobesColor.line,
                                  lineWidth: selected ? 1.5 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .opacity(selected ? 1 : 0.62)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(selected ? "\(title), showing" : "Show only \(title)")
    }
}

/// One collection: the looks as a filter over the pieces, then the pieces
/// themselves, grouped the way the Items tab groups them.
private struct RailCollectionDetail: View {
    let collection: RobesCollection

    /// Nil is the "All Items" stop; otherwise the look whose pieces are showing.
    @State private var activeLook: UUID? = nil

    private var lookCounts: [UUID: Int] { collection.lookCountByItem }

    /// How many of this collection's looks a piece belongs to. The number carries
    /// the weight so a nought jumps out of a scrolling list — that's what tells
    /// the wearer a piece is here on its own.
    private func lookCountText(for item: RobesItem) -> Text {
        let count = lookCounts[item.id] ?? 0
        let loose = count == 0

        // Every run styles itself, so nothing depends on what the row sets.
        // The number is always the emphasis; a loose piece darkens the whole
        // line as well, so a nought reads as different and not just smaller.
        let rest = RobesType.sans(10, loose ? .medium : .regular)
        let restColor = loose ? RobesColor.ink : RobesColor.clay

        return Text("In ")
                .font(rest)
                .foregroundStyle(restColor)
            + Text("\(count)")
                .font(RobesType.sans(12, .bold))
                .foregroundStyle(RobesColor.ink)
            + Text(" \(count == 1 ? "Look" : "Looks") in this Collection")
                .font(rest)
                .foregroundStyle(restColor)
    }

    /// Distinct pieces, narrowed to the selected look when there is one.
    private var visibleItems: [RobesItem] {
        guard let activeLook,
              let look = collection.looks.first(where: { $0.id == activeLook })
        else { return collection.allItems }

        var seen = Set<UUID>()
        return look.items.filter { seen.insert($0.id).inserted }
    }

    private func items(_ role: ItemRole) -> [RobesItem] {
        visibleItems.filter { $0.role == role }
    }

    /// Roles with something to show, in display order — as in the Items tab.
    private var visibleRoles: [ItemRole] {
        ItemRole.allCases.filter { !items($0).isEmpty }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    actions
                    filterStrip
                }
                .padding(.bottom, 6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(visibleRoles, id: \.self) { role in
                let items = items(role)
                Section {
                    ForEach(items) { item in
                        NavigationLink {
                            RailItemDetail(item: item)
                        } label: {
                            RailItemRow(item: item, detail: lookCountText(for: item))
                        }
                        .listRowBackground(RobesColor.card)
                        // A piece that's here via a look leaves by being removed
                        // from that look, so only loose pieces get these.
                        .swipeActions {
                            if lookCounts[item.id] == 0 {
                                Button(role: .destructive) {
                                    // Taking the piece out of the collection would happen here.
                                } label: {
                                    Label("Remove", systemImage: "minus.circle")
                                }

                                if !collection.looks.isEmpty {
                                    Button {
                                        // Adding it to one of the looks would happen here.
                                    } label: {
                                        Label("Add to look", systemImage: "plus")
                                    }
                                    .tint(RobesColor.umber)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        MicroLabel(role.plural, color: RobesColor.clay, size: 9)
                        Spacer()
                        MicroLabel("\(items.count)", color: RobesColor.taupe, size: 9)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RobesColor.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 12) }
        }
    }

    // Header — the name is the wearer's, so it's the editable thing
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            MicroLabel("Collection", color: RobesColor.taupe, size: 9)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(collection.name)
                    .font(RobesType.serif(30, .light, italic: true))
                    .foregroundStyle(RobesColor.ink)

                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundStyle(RobesColor.clay)
                    .frame(width: 22, height: 22)
                    .background(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
            }
            .padding(.top, 5)

            MicroLabel(collection.summary, color: RobesColor.clay, size: 9)
                .padding(.top, 3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    // No collage here — the collage is how a collection is recognised in the
    // scroller; inside, what matters is the contents. The two ways to grow a
    // collection lead the row.
    private var actions: some View {
        RailWrapLayout(spacing: 8) {
            RailButton(title: "Add looks", symbol: "plus.square.on.square", filled: true)
            RailButton(title: "Add pieces", symbol: "plus", filled: true)
            RailButton(title: "Rename", symbol: "pencil")
            RailButton(title: "Share", symbol: "square.and.arrow.up")
            RailButton(title: "Delete collection", symbol: "trash", destructive: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    /// The looks aren't links here — they're the filter over the pieces below.
    @ViewBuilder
    private var filterStrip: some View {
        if !collection.looks.isEmpty {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    RailCollectionFilterTile(
                        title: "All Items",
                        asset: nil,
                        count: collection.allItems.count,
                        selected: activeLook == nil
                    ) {
                        activeLook = nil
                    }

                    ForEach(collection.looks) { look in
                        RailCollectionFilterTile(
                            title: look.name,
                            asset: look.asset,
                            count: look.pieces.count,
                            selected: activeLook == look.id
                        ) {
                            // Tapping the selected look again clears the filter.
                            activeLook = activeLook == look.id ? nil : look.id
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 18)
        }
    }
}

// MARK: - Look detail

private struct RailLookDetail: View {
    let entry: PlannedLook

    init(entry: PlannedLook) { self.entry = entry }

    /// Opening a look with no day behind it — from an item, or a search result.
    init(look: RobesLook) { self.entry = PlannedLook(look: look) }

    private var look: RobesLook { entry.look }

    /// Only a day the wearer actually assigned is worth a chip here; a
    /// suggestion's day belongs to the Looks tab, not to the look itself.
    private var scheduledLabel: String? {
        entry.isScheduled ? entry.dateLabel : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header — state first, because it decides what this screen is for
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        RailLookBadge(look: look, size: 8)
                        RailWishlistBadge(look: look, size: 8)

                        if let scheduledLabel {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 8))
                                Text(scheduledLabel.uppercased())
                                    .font(RobesType.sans(8, .medium))
                                    .tracking(0.9)
                            }
                            .foregroundStyle(RobesColor.umber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(look.name)
                            .font(RobesType.serif(30, .light, italic: true))
                            .foregroundStyle(RobesColor.ink)

                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(RobesColor.clay)
                            .frame(width: 22, height: 22)
                            .background(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
                    }
                    .padding(.top, 7)

                    MicroLabel(look.origin.label, color: RobesColor.clay, size: 9)
                        .padding(.top, 3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                // The look, on body — scheduling and sharing ride on the photo itself
                VStack(spacing: 0) {
                    Image(look.asset)
                        .resizable()
                        .aspectRatio(4.0 / 5.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottom) {
                            HStack {
                                RailPhotoButton(symbol: "calendar", label: "Add this look to your plan")
                                Spacer()
                                RailPhotoButton(symbol: "square.and.arrow.up", label: "Share this look")
                            }
                            .padding(12)
                        }

                    Text(look.note)
                        .font(RobesType.serif(15, .light))
                        .italic()
                        .foregroundStyle(RobesColor.umber)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)

                    Divider().overlay(RobesColor.line)

                    HStack(spacing: 6) {
                        ForEach(look.tags, id: \.self) { tag in
                            Text(tag)
                                .font(RobesType.sans(11))
                                .foregroundStyle(RobesColor.umber)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(RobesColor.paperLight))
                        }
                        Spacer()
                        Text("Edit")
                            .font(RobesType.sans(11))
                            .underline()
                            .foregroundStyle(RobesColor.clay)
                    }
                    .padding(12)
                }
                .background(RobesColor.card)
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // A suggestion is a draft: the way out of it is to save it, with
                // or without changing it first. Filing it away is offered
                // whatever state the look is in.
                RailWrapLayout(spacing: 8) {
                    if look.isSuggested {
                        RailButton(title: "Save this look", symbol: "bookmark", filled: true)
                        RailButton(title: "Edit, then save", symbol: "pencil")
                        RailButton(title: "Add to plan", symbol: "calendar")
                    }
                    RailButton(title: "Add to collection", symbol: "square.stack")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // What's missing before the look can be worn as-is
                if look.wishlistCount > 0 {
                    HStack(spacing: 7) {
                        Image(systemName: "heart")
                            .font(.system(size: 10))
                        Text(look.wishlistCount == 1
                             ? "One piece isn't yours yet."
                             : "\(look.wishlistCount) pieces aren't yours yet.")
                            .font(RobesType.serif(14, .light))
                            .italic()
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(RobesColor.umber)
                    .padding(11)
                    .background(RobesColor.blush.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                // The pieces — one flat list, every row a way into the piece
                HStack {
                    MicroLabel("\(look.pieces.count) pieces", color: RobesColor.clay, size: 9)
                    Spacer()
                    Text(look.isSuggested ? "SWAP PIECES" : "EDIT & RESAVE")
                        .font(RobesType.sans(9, .medium))
                        .tracking(1.2)
                        .foregroundStyle(RobesColor.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
                }
                .padding(.horizontal, 16)
                .padding(.top, 26)
                .padding(.bottom, 10)

                ForEach(look.pieces) { piece in
                    NavigationLink {
                        RailItemDetail(item: piece.item, piece: piece)
                    } label: {
                        RailItemRow(item: piece.item, piece: piece, showsChevron: true)
                            .padding(10)
                            .background(RobesColor.card)
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    // Swiping is the quick way at a piece; the detail view has the same two.
                    .swipeActions {
                        Button(role: .destructive) {
                            // Removing the piece from the look would happen here.
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }

                        Button {
                            // Swapping in another piece would happen here.
                        } label: {
                            Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .tint(RobesColor.umber)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                RailWornHistory(look: look)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)

                Text(look.isSuggested ? "Dismiss this suggestion" : "Delete this look")
                    .font(RobesType.sans(12))
                    .underline()
                    .foregroundStyle(RobesColor.clay)
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
            }
        }
        .background(RobesColor.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 12) }
        }
    }
}

private struct RailWornHistory: View {
    let look: RobesLook

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                MicroLabel(look.wears > 0 ? "Worn · \(look.wears) times" : "Worn",
                           color: RobesColor.clay, size: 9)
                Spacer()
                Text("Add a date")
                    .font(RobesType.sans(11))
                    .underline()
                    .foregroundStyle(RobesColor.clay)
            }
            .padding(12)

            if look.wears == 0 {
                Text("Not worn yet. The counter started when you saved it.")
                    .font(RobesType.serif(14, .light))
                    .italic()
                    .foregroundStyle(RobesColor.taupe)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
            } else {
                ForEach(wornDates, id: \.self) { date in
                    HStack {
                        Text(date)
                            .font(RobesType.sans(12))
                            .foregroundStyle(RobesColor.ink)
                            .frame(width: 60, alignment: .leading)
                        Text("Worn as saved")
                            .font(RobesType.sans(12))
                            .foregroundStyle(RobesColor.clay)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .overlay(alignment: .top) {
                        Rectangle().fill(RobesColor.line).frame(height: 1)
                    }
                }
            }
        }
        .background(RobesColor.card)
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// Stand-in wear log derived from the sample look.
    private var wornDates: [String] {
        guard let last = look.lastWorn else { return [] }
        return look.wears > 1 ? [last, look.savedOnLabel] : [last]
    }
}

// MARK: - Item detail

private struct RailItemDetail: View {
    let item: RobesItem
    /// The piece you arrived from, when you arrived from inside a look. Its
    /// presence is what unlocks the swap and remove-from-this-look actions.
    var piece: LookPiece? = nil

    /// Every look this piece is part of.
    private var looks: [RobesLook] {
        RobesSample.allLooks.filter { look in look.items.contains { $0.id == item.id } }
    }

    /// The one quiet fact stated on the photo: what the piece has earned, or
    /// what it would cost. Replaces the old row of facts under the image.
    private var quietFact: String {
        if item.owned {
            switch item.wears {
            case 0: "Not worn yet"
            case 1: "Worn once"
            default: "Worn \(item.wears) times"
            }
        } else {
            [item.price, item.retailer].compactMap { $0 }.joined(separator: " · ")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                VStack(alignment: .leading, spacing: 0) {
                    if item.owned {
                        MicroLabel("In your wardrobe", color: RobesColor.sage, size: 9)
                    } else {
                        MicroLabel("Wishlist · not yours yet", color: RobesColor.umber, size: 9)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.name)
                            .font(RobesType.serif(28, .light, italic: true))
                            .foregroundStyle(RobesColor.ink)

                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(RobesColor.clay)
                            .frame(width: 22, height: 22)
                            .background(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
                    }
                    .padding(.top, 5)

                    Text(item.brand)
                        .font(RobesType.serif(15, .regular, italic: true))
                        .foregroundStyle(RobesColor.clay)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                // The piece
                VStack(spacing: 0) {
                    // The photo sits centred in the plate; the corner labels are
                    // overlays so their alignment can't pull the image off centre.
                    ZStack {
                        RobesColor.paperLight
                        Image(item.asset)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(22)
                    }
                    .frame(height: 320)
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        MicroLabel(item.role.badge, color: RobesColor.clay, size: 7, tracking: 1)
                            .padding(12)
                    }
                    // Wears (or the price of a wishlist piece) stated quietly,
                    // opposite the category badge.
                    .overlay(alignment: .topTrailing) {
                        if !quietFact.isEmpty {
                            MicroLabel(quietFact, color: RobesColor.taupe, size: 7, tracking: 1)
                                .padding(12)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        HStack {
                            RailPhotoButton(symbol: "camera", label: "Replace the photo")
                            Spacer()
                            RailPhotoButton(symbol: "square.and.arrow.up", label: "Share this piece")
                        }
                        .padding(12)
                    }

                    if let rationale = piece?.rationale {
                        Text(rationale)
                            .font(RobesType.serif(15, .light))
                            .italic()
                            .foregroundStyle(RobesColor.umber)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }

                    Divider().overlay(RobesColor.line)

                    // Auto-applied tags, editable by the wearer
                    HStack(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(RobesType.sans(11))
                                .foregroundStyle(RobesColor.umber)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(RobesColor.paperLight))
                        }
                        Spacer()
                        Text("Edit")
                            .font(RobesType.sans(11))
                            .underline()
                            .foregroundStyle(RobesColor.clay)
                    }
                    .padding(12)
                }
                .background(RobesColor.card)
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(RobesColor.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Managing the piece. Swapping and removing only mean something
                // inside a look, so they only appear when you came from one.
                // A wishlist piece also becomes yours here — no separate list to visit.
                RailWrapLayout(spacing: 8, lineSpacing: 8) {
                    if !item.owned {
                        RailButton(title: "Mark as owned", symbol: "checkmark", filled: true)
                    }

                    if piece != nil {
                        RailButton(title: "Swap out", symbol: "arrow.triangle.2.circlepath")
                        RailButton(title: "Remove from this look", symbol: "minus.circle")
                    }

                    RailButton(
                        title: piece == nil ? "Add to a look" : "Add to a different look",
                        symbol: "plus.square.on.square"
                    )
                    RailButton(title: "Add to collection", symbol: "square.stack")
                    RailButton(title: "Edit", symbol: "pencil")
                    RailButton(
                        title: item.owned ? "Remove from wardrobe" : "Remove from wishlist",
                        symbol: "trash",
                        destructive: true
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)

                if !looks.isEmpty {
                    MicroLabel(looks.count == 1 ? "In 1 look" : "In \(looks.count) looks",
                               color: RobesColor.clay, size: 9)
                        .padding(.horizontal, 16)
                        .padding(.top, 26)
                        .padding(.bottom, 10)

                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 10) {
                            ForEach(looks) { look in
                                NavigationLink {
                                    RailLookDetail(look: look)
                                } label: {
                                    RailLookThumb(look: look)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .scrollIndicators(.hidden)
                }

                Spacer(minLength: 40)
            }
        }
        .background(RobesColor.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 12) }
        }
    }
}

private struct RailLookThumb: View {
    let look: RobesLook

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(look.asset)
                .resizable()
                .aspectRatio(4.0 / 5.0, contentMode: .fill)
                .frame(width: 104, height: 130)
                .clipped()

            Text(look.name)
                .font(RobesType.serif(15, .regular))
                .foregroundStyle(RobesColor.ink)
                .lineLimit(1)
        }
        .frame(width: 104, alignment: .leading)
    }
}

// MARK: - Items

private struct RailItemsTab: View {
    @Binding var showProfile: Bool
    @State private var query = ""
    @State private var searching = false
    @State private var prompt = ""
    @State private var activeRole: ItemRole? = nil
    /// Narrows the list to what's actually in the wardrobe, dropping wishlist
    /// pieces. Combines with the category filter rather than replacing it.
    @State private var ownedOnly = false

    /// Owned and wishlist pieces of one category, in one list — wishlist pieces
    /// are marked in the row rather than split into a section of their own.
    private func items(_ role: ItemRole) -> [RobesItem] {
        var base = RobesSample.allItems.filter { $0.role == role }
        if ownedOnly {
            base = base.filter(\.owned)
        }
        guard !query.isEmpty else { return base }
        return base.filter { $0.matches(query) }
    }

    /// Roles with something to show, in display order.
    private var visibleRoles: [ItemRole] {
        let roles = activeRole.map { [$0] } ?? ItemRole.allCases
        return roles.filter { !items($0).isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 0) {
                        RailTopSlot(
                            searching: $searching,
                            query: $query,
                            prompt: $prompt,
                            searchPrompt: "Search your wardrobe",
                            capturePrompt: "Add a piece…",
                            captureSymbol: "hanger",
                            sources: RobesCapture.items
                        )

                        // Filter navigation, sitting directly above the items.
                        // "Owned" is a separate axis: it narrows whichever
                        // category is selected.
                        ScrollView(.horizontal) {
                            HStack(spacing: 7) {
                                RailChip(title: "Owned", active: ownedOnly) {
                                    ownedOnly.toggle()
                                }
                                RailChip(title: "All", active: activeRole == nil) {
                                    activeRole = nil
                                }
                                ForEach(ItemRole.allCases, id: \.self) { role in
                                    RailChip(title: role.plural, active: activeRole == role) {
                                        activeRole = activeRole == role ? nil : role
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .padding(.top, 14)
                    }
                    .padding(.bottom, 6)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if visibleRoles.isEmpty {
                    RailEmptyState(message: "Nothing here yet.", symbol: "hanger")
                        .padding(.top, 40)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                ForEach(visibleRoles, id: \.self) { role in
                    let items = items(role)
                    Section {
                        ForEach(items) { item in
                            NavigationLink {
                                RailItemDetail(item: item)
                            } label: {
                                RailItemRow(item: item)
                            }
                            .listRowBackground(RobesColor.card)
                        }
                    } header: {
                        HStack {
                            MicroLabel(role.plural, color: RobesColor.clay, size: 9)
                            Spacer()
                            MicroLabel("\(items.count)", color: RobesColor.taupe, size: 9)
                        }
                    } footer: {
                        if role == visibleRoles.last {
                            Text("Robes cleans up and tags each capture; the original photo is always kept.")
                                .font(RobesType.serif(13, .light))
                                .italic()
                                .foregroundStyle(RobesColor.taupe)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(RobesColor.paper)
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { Wordmark(size: 13) }
                ToolbarItem(placement: .topBarTrailing) {
                    RailSearchButton(searching: $searching)
                }
                ToolbarItem(placement: .topBarLeading) {
                    RailAvatarButton(showProfile: $showProfile)
                }
            }
        }
    }
}

private extension RobesItem {
    func matches(_ query: String) -> Bool {
        name.localizedCaseInsensitiveContains(query)
            || brand.localizedCaseInsensitiveContains(query)
            || tags.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

/// The one item row, used everywhere a piece is listed — the wardrobe, a look,
/// anywhere else. Passing `piece` adds the two facts that only matter inside a
/// look: what kind of piece fills the slot, and why it's there.
private struct RailItemRow: View {
    let item: RobesItem
    var piece: LookPiece? = nil
    /// Rows outside a `List` have to draw their own disclosure.
    var showsChevron: Bool = false
    /// A row inside a look always names the kind of piece; elsewhere it's opt-in.
    var showsRole: Bool = false
    /// Takes the place of the tags line where a list has something more useful
    /// to say in that space — the collection detail uses it to state how many of
    /// the collection's looks the piece belongs to. Styles its own runs.
    var detail: Text? = nil

    private var roleBadge: Bool { piece != nil || showsRole }

    var body: some View {
        HStack(alignment: piece == nil ? .center : .top, spacing: 12) {
            ZStack {
                RobesColor.paperLight
                Image(item.asset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(4)
            }
            .frame(width: 52, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(RobesType.serif(16, .regular))
                    .foregroundStyle(RobesColor.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    if roleBadge {
                        MicroLabel(item.role.badge, color: RobesColor.umber, size: 7, tracking: 1)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(RobesColor.paperLight))
                    }

                    MicroLabel(item.brand, color: RobesColor.taupe, size: 8, tracking: 1)

                    // Not yours yet — said in the row, so no separate list is needed
                    if !item.owned {
                        RailWishlistBadge()
                    }
                }

                // Auto-applied tags, editable by the wearer — unless the list
                // has better use for the line.
                if let detail {
                    detail.lineLimit(1)
                } else {
                    Text(item.tags.joined(separator: " · "))
                        .font(RobesType.sans(10))
                        .foregroundStyle(RobesColor.clay)
                        .lineLimit(1)
                }

                if let piece {
                    Text(piece.rationale)
                        .font(RobesType.serif(13, .light))
                        .italic()
                        .foregroundStyle(RobesColor.clay)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                }
            }

            Spacer(minLength: 0)

            if item.owned {
                Text(item.wearLabel)
                    .font(RobesType.sans(10))
                    .foregroundStyle(RobesColor.sage)
            } else if let price = item.price {
                Text(price)
                    .font(RobesType.sans(10))
                    .foregroundStyle(RobesColor.clay)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(RobesColor.taupe)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plan

/// What the calendar draws, top to bottom. A plan becomes one segment covering
/// its whole run, so a trip is one card rather than a stack of rows; the open
/// days around it are their own segments.
private enum RailCalendarSegment: Identifiable {
    case open(Date)
    case plan(RobesPlan, [Date])

    var id: String {
        switch self {
        case .open(let date): "open-\(date.timeIntervalSince1970)"
        case .plan(let plan, let dates):
            "plan-\(plan.id.uuidString)-\(dates.first?.timeIntervalSince1970 ?? 0)"
        }
    }
}

/// The calendar. Runs forward as far as the wearer scrolls, and reaches back a
/// week at a time when they pull past the top — the past is rarely what they
/// came for, and an endless scroll upward is just a way to lose your place.
private struct RailPlanTab: View {
    @Binding var showProfile: Bool

    /// Zero, so the list begins at today and the calendar opens there without
    /// needing to be scrolled. Pre-loading the previous week is what's wanted,
    /// but it depends on setting the initial scroll position, and six attempts
    /// at that — including `ScrollPosition.scrollTo(id:)` and a pre-layout
    /// `ScrollPosition(id:anchor:)`, which the documentation says should do
    /// exactly this — all left the view at the top of the content. Opening on
    /// today matters more day to day, so the past is fetched by pulling.
    @State private var pastWeeks = 0
    @State private var daysForward = 90
    /// Holds position when a pull prepends days above.
    @State private var position = ScrollPosition(idType: String.self)

    /// The segment today falls in, whether that's its own row or the plan card
    /// covering it. Found by searching the built segments rather than guessing
    /// at the id, so it matches whatever the list actually contains.
    private var todayID: String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return segments.first { segment in
            switch segment {
            case .open(let date):
                calendar.isDate(date, inSameDayAs: today)
            case .plan(_, let run):
                run.contains { calendar.isDate($0, inSameDayAs: today) }
            }
        }?.id
    }
    /// Loose assignments live here so they can actually be dragged about.
    @State private var loose: [Date: [PlanInstance]] = [:]
    @State private var seeded = false

    /// Seeded once, after the view appears, so each loose look keeps one
    /// identity for as long as the tab is alive. Deriving these on demand minted
    /// a new `PlanInstance` — and so a new id — on every read, which meant a
    /// dragged id matched nothing by the time the drop was handled.
    private func seed() {
        guard !seeded else { return }
        seeded = true

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var built: [Date: [PlanInstance]] = [:]

        for offset in -90...270 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let looks = RobesSample.plannedLooks(on: date)
            guard !looks.isEmpty else { continue }
            built[calendar.startOfDay(for: date)] = looks.map { PlanInstance.look($0) }
        }
        loose = built
    }

    private var dates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-(pastWeeks * 7)...daysForward).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }

    private var segments: [RailCalendarSegment] {
        var result: [RailCalendarSegment] = []
        let all = dates
        var index = 0

        while index < all.count {
            let date = all[index]
            guard let plan = RobesSample.plan(covering: date) else {
                result.append(.open(date))
                index += 1
                continue
            }

            // Gather the whole run this plan covers.
            var run: [Date] = []
            while index < all.count,
                  let next = RobesSample.plan(covering: all[index]), next.id == plan.id {
                run.append(all[index])
                index += 1
            }

            // A day the plan starts or ends on can also hold something outside
            // it. That shows as its own row, before the plan or after it.
            if let first = run.first, !looseEntries(on: first).isEmpty {
                result.append(.open(first))
            }
            result.append(.plan(plan, run))
            if run.count > 1, let last = run.last, !looseEntries(on: last).isEmpty {
                result.append(.open(last))
            }
        }
        return result
    }

    private func looseEntries(on date: Date) -> [PlanInstance] {
        loose[Calendar.current.startOfDay(for: date)] ?? []
    }

    var body: some View {
        // Built once per pass and captured by the row callbacks. Recomputing it
        // inside `onAppear` meant rebuilding every plan for every date twice on
        // each row that scrolled into view.
        let segments = self.segments
        let lastID = segments.last?.id

        return NavigationStack {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(segments) { segment in
                            switch segment {
                            case .open(let date):
                                RailCalendarOpenDay(
                                    date: date,
                                    entries: looseEntries(on: date)
                                ) { ids, before in
                                    move(ids, to: date, before: before)
                                }
                                .onAppear { extend(segment.id, lastID) }

                            case .plan(let plan, let run):
                                RailCalendarPlanCard(plan: plan, run: run)
                                    .onAppear { extend(segment.id, lastID) }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition($position, anchor: .top)
            // A pull at the top fetches the previous week. This has to be a
            // gesture, not a reaction to the scroll position: prepending days
            // moves what's at the top, so anything watching the top row ends up
            // retriggering itself and walking back months.
            .refreshable {
                guard pastWeeks < 52 else { return }
                pastWeeks += 1
            }
            .task { seed() }
            .background(RobesColor.paper)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { Wordmark(size: 13) }
                ToolbarItem(placement: .topBarLeading) {
                    RailAvatarButton(showProfile: $showProfile)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    RailAddMenu {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(RobesColor.ink)
                    }
                }
            }
        }
    }

    /// Grows the window forward as the end comes into view. Only forward:
    /// appending doesn't move what's already on screen, so it can't feed back
    /// on itself the way reaching backwards did.
    private func extend(_ id: String, _ lastID: String?) {
        if id == lastID, daysForward < 730 { daysForward += 60 }
    }

    /// Moves loose looks between days, and within a day when dropped onto one
    /// of its own entries. Only the instance's id travels on the drag — the
    /// look itself is looked back up here, so nothing has to be serialisable.
    private func move(_ ids: [String], to date: Date, before target: UUID?) {
        let moving = Set(ids.compactMap(UUID.init(uuidString:)))
        guard !moving.isEmpty else { return }

        let calendar = Calendar.current
        var moved: [PlanInstance] = []

        // Lift from whichever day held them. Keys are snapshotted because the
        // dictionary is written to inside the loop.
        for key in Array(loose.keys) {
            var entries = loose[key] ?? []
            let count = entries.count
            entries.removeAll { entry in
                guard moving.contains(entry.id) else { return false }
                moved.append(entry)
                return true
            }
            if entries.count != count { loose[key] = entries }
        }

        guard !moved.isEmpty else { return }

        let key = calendar.startOfDay(for: date)
        var entries = loose[key] ?? []
        if let target, let at = entries.firstIndex(where: { $0.id == target }) {
            entries.insert(contentsOf: moved, at: at)
        } else {
            entries.append(contentsOf: moved)
        }
        loose[key] = entries
    }
}

/// A day with nothing but the wearer's own assignments on it.
///
/// The whole row is a drop target, so a look can be moved onto a day that has
/// nothing on it yet — there'd be no row to aim at otherwise. Dropping onto one
/// of the day's own looks puts the dragged one in front of it.
private struct RailCalendarOpenDay: View {
    let date: Date
    let entries: [PlanInstance]
    /// Ids being dropped, and the entry to land in front of when there is one.
    let onDrop: ([String], UUID?) -> Void

    @State private var targeted = false

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        HStack(alignment: entries.isEmpty ? .center : .top, spacing: 14) {
            RailCalendarDateBlock(date: date, onShade: false)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(entries) { entry in
                    RailPlanEntryRow(entry: entry, showsHandle: true)
                        .draggable(entry.id.uuidString)
                        .dropDestination(for: String.self) { ids, _ in
                            onDrop(ids, entry.id)
                            return true
                        }
                }

                RailAddMenu {
                    RailAddLabel()
                }
                // Kept clear of the last look, and evenly spaced against the
                // rule that closes the day, so neither is a mis-tap risk.
                .padding(.top, entries.isEmpty ? 0 : 8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background {
            if targeted {
                RobesColor.sage.opacity(0.16)
            } else if isToday {
                RobesColor.blush.opacity(0.3)
            }
        }
        // Held over the day for a moment, it says it will take the drop.
        .overlay {
            if targeted {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(RobesColor.sage, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .padding(.horizontal, 8)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RobesColor.line)
                .frame(height: 1)
                .padding(.leading, 16)
        }
        .dropDestination(for: String.self) { ids, _ in
            onDrop(ids, nil)
            return true
        } isTargeted: { hovering in
            targeted = hovering
        }
        .animation(.easeOut(duration: 0.15), value: targeted)
    }
}

/// A plan, however many days it spans, drawn as one card sitting on top of the
/// calendar rather than as a stretch of it.
private struct RailCalendarPlanCard: View {
    let plan: RobesPlan
    let run: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                RailPlanDetail(plan: plan)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "airplane")
                        .font(.system(size: 11))
                    Text(plan.name)
                        .font(RobesType.serif(18, .regular))
                    Spacer(minLength: 4)
                    if run.count > 1 {
                        MicroLabel(plan.dateRangeLabel, color: RobesColor.umber, size: 8)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(RobesColor.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            ForEach(run, id: \.self) { date in
                Rectangle()
                    .fill(RobesColor.umber.opacity(0.18))
                    .frame(height: 1)

                HStack(alignment: .top, spacing: 14) {
                    RailCalendarDateBlock(date: date, onShade: true)

                    VStack(alignment: .leading, spacing: 8) {
                        // A one-off plan's event carries the plan's own name, so
                        // showing it here would just say the same thing twice
                        // under the card's title.
                        if let occasion = plan.day(on: date)?.occasion, occasion != plan.name {
                            Text(occasion)
                                .font(RobesType.serif(15, .light, italic: true))
                                .foregroundStyle(RobesColor.umber)
                        }

                        // No handles: a plan's own entries are rearranged inside
                        // the plan, not out here on the calendar.
                        ForEach(plan.day(on: date)?.allEntries ?? []) { entry in
                            RailPlanEntryRow(entry: entry, showsHandle: false)
                        }

                        if plan.day(on: date)?.isEmpty ?? true {
                            NavigationLink {
                                RailPlanDetail(plan: plan)
                            } label: {
                                RailAddLabel()
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
        }
        .background(RobesColor.shade)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        // Layered over the calendar, not part of it.
        .shadow(color: RobesColor.ink.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

/// The date column, in one place so the open days and the plan cards agree.
private struct RailCalendarDateBlock: View {
    let date: Date
    /// True on a plan's darker ground, where the pale greys stop reading.
    let onShade: Bool

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            MicroLabel(date.formatted(.dateTime.weekday(.abbreviated)).uppercased(),
                       color: onShade ? RobesColor.umber : (isToday ? RobesColor.ink : RobesColor.taupe),
                       size: 8)
            Text(date.formatted(.dateTime.day()))
                .font(RobesType.serif(24, .light))
                .foregroundStyle(onShade || isToday ? RobesColor.ink : RobesColor.clay)
            MicroLabel(date.formatted(.dateTime.month(.abbreviated)).uppercased(),
                       color: onShade ? RobesColor.umber : RobesColor.taupe,
                       size: 7)
        }
        .frame(width: 34, alignment: .leading)
    }
}

private struct RailAddLabel: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "plus")
                .font(.system(size: 9, weight: .medium))
            MicroLabel("Add", color: RobesColor.taupe, size: 9)
        }
        .foregroundStyle(RobesColor.taupe)
        // A bigger target than the glyphs alone.
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

/// The add affordance, wherever it appears. A menu rather than an action sheet,
/// so the choices open at the button that was tapped instead of somewhere else
/// on screen.
private struct RailAddMenu<Label: View>: View {
    @ViewBuilder let label: Label

    var body: some View {
        Menu {
            Button {
                // Picking a look would happen here.
            } label: {
                SwiftUI.Label("Look", systemImage: "square.stack")
            }

            Button {
                // Picking an item would happen here.
            } label: {
                SwiftUI.Label("Item", systemImage: "hanger")
            }

            Button {
                // Starting a plan would happen here.
            } label: {
                SwiftUI.Label("Plan", systemImage: "airplane")
            }
        } label: {
            label
        }
        .accessibilityLabel("Add a look, an item or a plan")
    }
}

// MARK: - Plans

/// One plan: what it's bringing that isn't spoken for yet, then a slot per day
/// of its range, each holding the events that day dresses for.
private struct RailPlanDetail: View {
    let plan: RobesPlan

    @State private var days: [PlanDay]
    @State private var unassigned: [PlanInstance]
    @State private var trayTargeted = false

    init(plan: RobesPlan) {
        self.plan = plan
        _days = State(initialValue: plan.days)
        _unassigned = State(initialValue: plan.unassigned)
    }

    /// Recomputed from the live days, so counts and suggestion costs follow
    /// along as things are moved, accepted and dismissed.
    private var live: RobesPlan {
        var copy = plan
        copy.days = days
        copy.unassigned = unassigned
        return copy
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                actions
                tray
                dayList

                Spacer(minLength: 40)
            }
        }
        .background(RobesColor.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 12) }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            MicroLabel("Plan", color: RobesColor.taupe, size: 9)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(plan.name)
                    .font(RobesType.serif(30, .light, italic: true))
                    .foregroundStyle(RobesColor.ink)
                    .lineSpacing(4)

                RailEditButton(label: "Rename this plan")
            }
            .padding(.top, 10)

            // The dates carry the plan, so they're stated properly rather than
            // tucked into a caption.
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(live.dateRangeLabel)
                    .font(RobesType.serif(21, .light))
                    .foregroundStyle(RobesColor.umber)

                RailEditButton(label: "Change the dates")
            }
            .padding(.top, 14)

            HStack(spacing: 6) {
                MicroLabel("\(days.count) \(days.count == 1 ? "day" : "days")",
                           color: RobesColor.clay, size: 9)
                RailDot()
                MicroLabel("\(live.lookCount) \(live.lookCount == 1 ? "look" : "looks")",
                           color: RobesColor.clay, size: 9)
                RailDot()
                MicroLabel("\(live.itemCount) \(live.itemCount == 1 ? "piece" : "pieces")",
                           color: RobesColor.clay, size: 9)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var actions: some View {
        RailWrapLayout(spacing: 8) {
            RailButton(title: "Suggest looks", symbol: "sparkles", filled: true) {
                suggestIntoTray()
            }
            RailButton(title: "Share", symbol: "square.and.arrow.up")
            RailButton(title: "Duplicate", symbol: "plus.square.on.square")
            RailButton(title: "Delete plan", symbol: "trash", destructive: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
    }

    /// Puts a few looks the plan isn't already carrying into the tray, for the
    /// wearer to place on days themselves.
    private func suggestIntoTray() {
        var used = Set(unassigned.compactMap { entry -> UUID? in
            if case .look(let look) = entry.member { return look.id }
            return nil
        })
        for day in days {
            for entry in day.allEntries {
                if case .look(let look) = entry.member { used.insert(look.id) }
            }
        }

        let fresh = RobesSample.allLooks.filter { !used.contains($0.id) }.shuffled().prefix(3)
        unassigned.append(contentsOf: fresh.map { PlanInstance.look($0) })
    }

    // MARK: Not assigned

    /// What the plan is bringing that no day claims yet.
    @ViewBuilder
    private var tray: some View {
        if !unassigned.isEmpty {
            MicroLabel("Not assigned", color: RobesColor.clay, size: 9)
                .padding(.horizontal, 16)
                .padding(.top, 26)
                .padding(.bottom, 10)

            // Tight, because this list can get long.
            VStack(spacing: 5) {
                ForEach($unassigned) { $entry in
                    RailPlanEntryLink(entry: entry)
                        .dropDestination(for: String.self) { ids, _ in
                            move(ids, to: .tray, before: entry.id)
                            return true
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                let id = entry.id
                                unassigned.removeAll { $0.id == id }
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }

                            Button {
                                unassigned.append(entry.duplicated)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(RobesColor.umber)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background {
                if trayTargeted {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RobesColor.sage.opacity(0.16))
                        .padding(.horizontal, 8)
                }
            }
            // A drop that doesn't land on a specific row — including onto an
            // otherwise-empty gap — still unassigns it.
            .dropDestination(for: String.self) { ids, _ in
                move(ids, to: .tray)
                return true
            } isTargeted: { trayTargeted = $0 }
            .animation(.easeOut(duration: 0.15), value: trayTargeted)
        }
    }

    // MARK: Days

    /// The plan's own stretch of calendar. Carries the same ground as the plan
    /// cards in the Plan tab — so it reads as the thing that was tapped to get
    /// here — but it isn't a card: it runs the full width, with days separated
    /// by rules rather than boxed, which is also the cue that it can be dragged
    /// onto exactly like the main calendar.
    private var dayList: some View {
        VStack(spacing: 0) {
            ForEach($days) { $day in
                let dayID = $day.wrappedValue.id
                RailPlanDaySlot(
                    day: $day,
                    newItemCount: { live.newItemCount(accepting: $0) },
                    suggest: { suggestion(for: $0) },
                    onDropToDay: { ids, before in move(ids, to: .day(dayID), before: before) },
                    onDropToEvent: { eventID, ids, before in
                        move(ids, to: .event(dayID, eventID), before: before)
                    }
                )
            }
        }
        .background(RobesColor.shade)
        .padding(.top, 26)
    }

    /// Stands in for asking Robes. The event's title is the prompt, so the
    /// stand-in at least answers it in kind: it prefers a look whose tags echo
    /// words in the title, and falls back to something not already in the plan.
    private func suggestion(for event: PlanEvent) -> RobesLook? {
        let prompt = event.title.lowercased()
        let alreadyHere = Set(days.flatMap(\.allEntries).compactMap { entry -> UUID? in
            if case .look(let look) = entry.member { return look.id }
            return nil
        })

        let candidates = RobesSample.allLooks.filter { !alreadyHere.contains($0.id) }
        let matching = candidates.filter { look in
            look.tags.contains { prompt.contains($0.lowercased()) }
                || prompt.contains(look.name.lowercased())
        }
        return matching.randomElement() ?? candidates.randomElement()
    }

    // MARK: Moving looks and pieces around

    /// Moves an entry between the tray, a day's own list, and a specific event
    /// on a day — dragged out of whichever of those it was already in.
    ///
    /// Plain `draggable`/`dropDestination` rather than `reorderContainer`: a
    /// day or event with nothing in it yet has no rows for a reorder container
    /// to anchor a drop to, which made empty days undroppable. Each row is its
    /// own drop target for ordering, and the enclosing day and event are drop
    /// targets in their own right so a drop that misses every row still lands
    /// somewhere sensible.
    private func move(_ ids: [String], to target: RailPlanDropTarget, before: UUID? = nil) {
        let moving = Set(ids.compactMap(UUID.init(uuidString:)))
        guard !moving.isEmpty else { return }

        var moved: [PlanInstance] = []

        func lift(_ entries: inout [PlanInstance]) {
            entries.removeAll { entry in
                guard moving.contains(entry.id) else { return false }
                moved.append(entry)
                return true
            }
        }

        lift(&unassigned)
        for dayIndex in days.indices {
            lift(&days[dayIndex].entries)
            for eventIndex in days[dayIndex].events.indices {
                lift(&days[dayIndex].events[eventIndex].entries)
            }
        }
        guard !moved.isEmpty else { return }

        func insert(into entries: inout [PlanInstance]) {
            if let before, let at = entries.firstIndex(where: { $0.id == before }) {
                entries.insert(contentsOf: moved, at: at)
            } else {
                entries.append(contentsOf: moved)
            }
        }

        switch target {
        case .tray:
            insert(into: &unassigned)

        case .day(let dayID):
            guard let dayIndex = days.firstIndex(where: { $0.id == dayID }) else {
                unassigned.append(contentsOf: moved)
                return
            }
            insert(into: &days[dayIndex].entries)

        case .event(let dayID, let eventID):
            guard let dayIndex = days.firstIndex(where: { $0.id == dayID }),
                  let eventIndex = days[dayIndex].events.firstIndex(where: { $0.id == eventID })
            else {
                unassigned.append(contentsOf: moved)
                return
            }
            insert(into: &days[dayIndex].events[eventIndex].entries)
        }
    }
}

/// Where a dragged look or piece can land inside a plan.
private enum RailPlanDropTarget {
    case tray
    case day(PlanDay.ID)
    case event(PlanDay.ID, PlanEvent.ID)
}

/// One day of a plan: its events, each with what it's wearing, plus the ways to
/// add another event or ask for a look.
///
/// A drop target in its own right — held over the day generally (as opposed to
/// over one of its rows or events), a drag settles unheaded at the top of the
/// day, the same as a look assigned straight to a date on the main calendar.
private struct RailPlanDaySlot: View {
    @Binding var day: PlanDay
    let newItemCount: (RobesLook) -> Int
    let suggest: (PlanEvent) -> RobesLook?
    let onDropToDay: ([String], UUID?) -> Void
    let onDropToEvent: (UUID, [String], UUID?) -> Void

    @State private var targeted = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RailCalendarDateBlock(date: day.date, onShade: true)

            VStack(alignment: .leading, spacing: 14) {
                // Anything dropped on the day rather than into one of its
                // events sits at the top, unheaded.
                if !day.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach($day.entries) { $entry in
                            RailPlanEntryLink(entry: entry, showsHandle: true)
                                .dropDestination(for: String.self) { ids, _ in
                                    onDropToDay(ids, entry.id)
                                    return true
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        let id = entry.id
                                        day.entries.removeAll { $0.id == id }
                                    } label: {
                                        Label("Unassign", systemImage: "minus.circle")
                                    }
                                }
                        }
                    }
                }

                ForEach($day.events) { $event in
                    let eventID = $event.wrappedValue.id
                    RailPlanEventBlock(
                        event: $event,
                        newItemCount: newItemCount,
                        suggest: suggest,
                        onDrop: { ids, before in onDropToEvent(eventID, ids, before) }
                    )
                }

                // Naming an event is optional, so this stays a placeholder. It's
                // the same element whether the day has no events yet or the
                // wearer wants another one under the last.
                RailAddEventButton(
                    title: day.events.isEmpty ? "Add an event" : "Add another event"
                ) {
                    day.events.append(PlanEvent(title: "New event"))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background {
            if targeted {
                RobesColor.sage.opacity(0.16)
            }
        }
        .overlay {
            if targeted {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(RobesColor.sage, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .padding(6)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RobesColor.umber.opacity(0.16))
                .frame(height: 1)
                .padding(.leading, 16)
        }
        .dropDestination(for: String.self) { ids, _ in
            onDropToDay(ids, nil)
            return true
        } isTargeted: { targeted = $0 }
        .animation(.easeOut(duration: 0.15), value: targeted)
    }
}

/// One event on a day: its name, what's assigned to it, and the way to ask for
/// a look. A drop target of its own, nested inside the day's — held over the
/// event specifically, a drag settles inside it rather than loose on the day.
private struct RailPlanEventBlock: View {
    @Binding var event: PlanEvent
    let newItemCount: (RobesLook) -> Int
    let suggest: (PlanEvent) -> RobesLook?
    let onDrop: ([String], UUID?) -> Void

    @State private var targeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(event.title)
                    .font(RobesType.serif(16, .light, italic: true))
                    .foregroundStyle(RobesColor.umber)

                RailEditButton(label: "Rename \(event.title)")

                Spacer(minLength: 0)
            }

            ForEach($event.entries) { $entry in
                RailPlanEntryLink(entry: entry, showsHandle: true)
                    .dropDestination(for: String.self) { ids, _ in
                        onDrop(ids, entry.id)
                        return true
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            let id = entry.id
                            event.entries.removeAll { $0.id == id }
                        } label: {
                            Label("Unassign", systemImage: "minus.circle")
                        }
                    }
            }

            if let suggested = event.suggestion {
                RailSuggestedLookCard(
                    look: suggested,
                    newItems: newItemCount(suggested),
                    accept: {
                        event.entries.append(.look(suggested))
                        event.suggestion = nil
                    },
                    refresh: { event.suggestion = suggest(event) },
                    dismiss: { event.suggestion = nil }
                )
            } else {
                RailSuggestLookSlot(hasEventName: !event.title.isEmpty) {
                    event.suggestion = suggest(event)
                }
            }
        }
        .padding(8)
        .contentShape(Rectangle())
        .background {
            if targeted {
                RoundedRectangle(cornerRadius: 3).fill(RobesColor.sage.opacity(0.16))
            }
        }
        .overlay {
            if targeted {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(RobesColor.sage, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .dropDestination(for: String.self) { ids, _ in
            onDrop(ids, nil)
            return true
        } isTargeted: { targeted = $0 }
        .animation(.easeOut(duration: 0.15), value: targeted)
    }
}

/// A look or piece row that opens its own detail view when tapped, and can be
/// picked up and dragged to another day, event, or back to the tray.
private struct RailPlanEntryLink: View {
    let entry: PlanInstance
    var showsHandle: Bool = true

    var body: some View {
        NavigationLink {
            destination
        } label: {
            RailPlanEntryRow(entry: entry, showsHandle: showsHandle)
        }
        .buttonStyle(.plain)
        .draggable(entry.id.uuidString)
    }

    @ViewBuilder
    private var destination: some View {
        switch entry.member {
        case .look(let look):
            RailLookDetail(look: look)
        case .item(let item):
            RailItemDetail(item: item)
        }
    }
}

/// A look Robes is proposing for an event. Same shape as an assigned look so
/// it's read the same way, but outlined rather than solid — it isn't committed
/// to yet — and it says what accepting it would add to the plan.
private struct RailSuggestedLookCard: View {
    let look: RobesLook
    let newItems: Int
    let accept: () -> Void
    let refresh: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RobesColor.paperLight
                    .overlay {
                        Image(look.asset)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 38, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(look.name)
                        .font(RobesType.serif(16, .regular))
                        .foregroundStyle(RobesColor.ink)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        MicroLabel("Suggestion", color: RobesColor.umber, size: 6, tracking: 0.9)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(RobesColor.paperLight))

                        // What taking it would cost.
                        MicroLabel(
                            newItems == 0
                                ? "Nothing new to bring"
                                : "Adds \(newItems) \(newItems == 1 ? "piece" : "pieces")",
                            color: newItems == 0 ? RobesColor.sage : RobesColor.clay,
                            size: 8, tracking: 1
                        )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(8)

            Rectangle().fill(RobesColor.line).frame(height: 1)

            HStack(spacing: 0) {
                suggestionAction("Accept", symbol: "checkmark", action: accept)
                Rectangle().fill(RobesColor.line).frame(width: 1, height: 26)
                suggestionAction("Another", symbol: "arrow.clockwise", action: refresh)
                Rectangle().fill(RobesColor.line).frame(width: 1, height: 26)
                suggestionAction("Dismiss", symbol: "xmark", action: dismiss)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(RobesColor.taupe, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        }
    }

    private func suggestionAction(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .medium))
                MicroLabel(title, color: RobesColor.clay, size: 8)
            }
            .foregroundStyle(RobesColor.clay)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The inline edit affordance. A bare glyph read as decoration, so it says what
/// it does.
private struct RailEditButton: View {
    let label: String

    var body: some View {
        Button {
            // Editing would start here.
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                Text("Edit")
                    .font(RobesType.sans(10, .medium))
                    .tracking(0.8)
            }
            .foregroundStyle(RobesColor.clay)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Naming an event is optional — plenty of days just get a look dropped on
/// them — so this is a quiet placeholder rather than a filled control. The same
/// element appends a further event at the foot of a day, so the two read as the
/// same act.
private struct RailAddEventButton: View {
    var title: String = "Add an event"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .medium))
                Text(title)
                    .font(RobesType.serif(15, .light, italic: true))
            }
            .foregroundStyle(RobesColor.taupe)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The empty slot a suggested look would fill. Same footprint as an assigned
/// look so the day reads consistently, outlined because nothing's there yet.
private struct RailSuggestLookSlot: View {
    let hasEventName: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15))
                    .foregroundStyle(RobesColor.clay)
                    .frame(width: 38, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Suggest a look")
                        .font(RobesType.serif(16, .regular))
                        .foregroundStyle(RobesColor.umber)
                    MicroLabel(hasEventName ? "From this event's name" : "Name the event to guide it",
                               color: RobesColor.taupe, size: 8, tracking: 1)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(RobesColor.taupe, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .buttonStyle(.plain)
    }
}

/// A look or a piece assigned to a day, in wearing order.
private struct RailPlanEntryRow: View {
    let entry: PlanInstance
    /// Only shown where the row can actually be dragged — a handle on something
    /// fixed is a promise the row can't keep.
    var showsHandle: Bool = true

    private var member: CollectionMember { entry.member }

    var body: some View {
        HStack(spacing: 10) {
            RobesColor.paperLight
                .overlay {
                    switch member {
                    case .look(let look):
                        Image(look.asset).resizable().aspectRatio(contentMode: .fill)
                    case .item(let item):
                        Image(item.asset).resizable().aspectRatio(contentMode: .fit).padding(3)
                    }
                }
                .frame(width: 38, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(RobesType.serif(16, .regular))
                    .foregroundStyle(RobesColor.ink)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    switch member {
                    case .look(let look):
                        RailLookBadge(look: look, size: 6, compact: true)
                        MicroLabel("\(look.pieces.count) pieces",
                                   color: RobesColor.taupe, size: 8, tracking: 1)
                    case .item(let item):
                        MicroLabel(item.role.badge, color: RobesColor.taupe, size: 8, tracking: 1)
                        if !item.owned { RailWishlistBadge(size: 6) }
                    }
                }
            }

            Spacer(minLength: 0)

            // Drag to reorder within the day, or across to another one.
            if showsHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11))
                    .foregroundStyle(RobesColor.line)
            }
        }
        .padding(8)
        .background(RobesColor.card)
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(RobesColor.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Profile

private struct RailProfile: View {
    @Environment(\.dismiss) private var dismiss
    @State private var autoTag = true
    @State private var autoCleanUp = true
    @State private var keepOriginals = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Text("A")
                            .font(RobesType.serif(24, .light))
                            .foregroundStyle(RobesColor.umber)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(RobesColor.paperLight))
                            .overlay(Circle().strokeBorder(RobesColor.line, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Anna")
                                .font(RobesType.serif(24, .light, italic: true))
                                .foregroundStyle(RobesColor.ink)
                            MicroLabel("Dublin · \(RobesSample.ownedItems.count) pieces", color: RobesColor.taupe, size: 8)
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(RobesColor.card)
                }

                Section {
                    Toggle(isOn: $autoTag) {
                        Text("Auto-tag captures").font(RobesType.sans(14))
                    }
                    Toggle(isOn: $autoCleanUp) {
                        Text("Clean up item photos").font(RobesType.sans(14))
                    }
                    Toggle(isOn: $keepOriginals) {
                        Text("Keep original photos").font(RobesType.sans(14))
                    }
                } header: {
                    MicroLabel("Capture", color: RobesColor.clay, size: 9)
                } footer: {
                    Text("Originals are never overwritten — you can restore any item to the photo you took.")
                        .font(RobesType.serif(13, .light))
                        .italic()
                        .foregroundStyle(RobesColor.taupe)
                }
                .tint(RobesColor.sage)
                .listRowBackground(RobesColor.card)

                Section {
                    ForEach(["Your model", "Sharing & Instagram", "Notifications", "Privacy"], id: \.self) { row in
                        HStack {
                            Text(row).font(RobesType.sans(14))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(RobesColor.taupe)
                        }
                    }
                } header: {
                    MicroLabel("Account", color: RobesColor.clay, size: 9)
                }
                .listRowBackground(RobesColor.card)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(RobesColor.paper)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(RobesType.sans(14, .medium))
                        .tint(RobesColor.ink)
                }
            }
        }
    }
}

// MARK: - Shared pieces

/// The top of a tab: the capture bar, or the search field once search is asked for.
private struct RailTopSlot: View {
    @Binding var searching: Bool
    @Binding var query: String
    @Binding var prompt: String
    let searchPrompt: String
    let capturePrompt: String
    let captureSymbol: String
    let sources: [CaptureSource]

    var body: some View {
        if searching {
            RailSearchBar(prompt: searchPrompt, query: $query) {
                query = ""
                searching = false
            }
        } else {
            RailCaptureBar(prompt: capturePrompt, symbol: captureSymbol, sources: sources, text: $prompt)
        }
    }
}

/// Every way in to something new, collapsed into one bar: describe it, or reach
/// for a camera, the library or a link.
private struct RailCaptureBar: View {
    let prompt: String
    let symbol: String
    let sources: [CaptureSource]
    @Binding var text: String

    private var quick: [CaptureSource] { Array(sources.prefix(3)) }
    private var overflow: [CaptureSource] { Array(sources.dropFirst(3)) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .foregroundStyle(RobesColor.clay)

            TextField(prompt, text: $text)
                .font(RobesType.sans(13))
                .foregroundStyle(RobesColor.ink)
                .textFieldStyle(.plain)

            Rectangle()
                .fill(RobesColor.line)
                .frame(width: 1, height: 18)

            ForEach(quick) { source in
                Button {
                    // Capture flow would start here.
                } label: {
                    Image(systemName: source.symbol)
                        .font(.system(size: 12))
                        .foregroundStyle(RobesColor.clay)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(source.title)
            }

            if !overflow.isEmpty {
                Menu {
                    ForEach(overflow) { source in
                        Button {
                            // Capture flow would start here.
                        } label: {
                            Label(source.title, systemImage: source.symbol)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundStyle(RobesColor.clay)
                }
                .accessibilityLabel("More ways to capture")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Capsule().fill(RobesColor.card))
        .overlay(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
    }
}

private struct RailSearchBar: View {
    let prompt: String
    @Binding var query: String
    let onClose: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(RobesColor.clay)

            TextField(prompt, text: $query)
                .font(RobesType.sans(13))
                .foregroundStyle(RobesColor.ink)
                .textFieldStyle(.plain)
                .focused($focused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(RobesColor.taupe)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }

            Rectangle()
                .fill(RobesColor.line)
                .frame(width: 1, height: 18)

            Button {
                focused = false
                onClose()
            } label: {
                MicroLabel("Done", color: RobesColor.ink, size: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Capsule().fill(RobesColor.card))
        .overlay(Capsule().strokeBorder(RobesColor.line, lineWidth: 1))
        .onAppear { focused = true }
    }
}

private struct RailSearchButton: View {
    @Binding var searching: Bool

    var body: some View {
        Button {
            searching = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(RobesColor.ink)
        }
        .accessibilityLabel("Search")
    }
}

private struct RailSectionHead: View {
    let label: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MicroLabel(label, color: RobesColor.taupe, size: 9)
                .padding(.bottom, 12)

            Text(title)
                .font(RobesType.serif(30, .light))
                .foregroundStyle(RobesColor.ink)
            Text(subtitle)
                .font(RobesType.serif(30, .light, italic: true))
                .foregroundStyle(RobesColor.clay)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
}

private struct RailAvatarButton: View {
    @Binding var showProfile: Bool

    var body: some View {
        Button {
            showProfile = true
        } label: {
            Text("A")
                .font(RobesType.serif(12, .regular))
                .foregroundStyle(RobesColor.umber)
                .frame(width: 26, height: 26)
                .background(Circle().fill(RobesColor.paperLight))
                .overlay(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
        }
        .accessibilityLabel("Profile and settings")
    }
}

private struct RailChip: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RobesType.sans(11, active ? .medium : .regular))
                .foregroundStyle(active ? RobesColor.paperLight : RobesColor.clay)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
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

/// Lays subviews out left to right, wrapping onto a new line whenever the next
/// one would overflow the proposed width. Used for action rows that must stay
/// fully visible instead of scrolling off the edge.
private struct RailWrapLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    /// One row of the layout: the subviews it holds, plus its measured size.
    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let lines = lines(for: sizes, maxWidth: proposal.width ?? .infinity)
        let height = lines.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(lines.count - 1, 0))
        // Report the widest line so the row shrinks to fit narrow containers.
        let width = proposal.width ?? lines.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let lines = lines(for: sizes, maxWidth: bounds.width)
        var y = bounds.minY

        for line in lines {
            var x = bounds.minX + leadingOffset(lineWidth: line.width, containerWidth: bounds.width)

            for index in line.indices {
                let size = sizes[index]
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }

            y += line.height + lineSpacing
        }
    }

    /// Groups subview sizes into rows that each fit within `maxWidth`.
    private func lines(for sizes: [CGSize], maxWidth: CGFloat) -> [Line] {
        var lines: [Line] = []
        var current = Line()

        for (index, size) in sizes.enumerated() {
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

            if needed > maxWidth, !current.indices.isEmpty {
                lines.append(current)
                current = Line()
            }

            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }

        if !current.indices.isEmpty { lines.append(current) }
        return lines
    }

    private func leadingOffset(lineWidth: CGFloat, containerWidth: CGFloat) -> CGFloat {
        switch alignment {
        case .center: (containerWidth - lineWidth) / 2
        case .trailing: containerWidth - lineWidth
        default: 0
        }
    }
}

private struct RailButton: View {
    let title: String
    var symbol: String? = nil
    var filled: Bool = false
    var destructive: Bool = false
    var action: (() -> Void)? = nil

    private var foreground: Color {
        if filled { RobesColor.paperLight } else if destructive { RobesColor.clay } else { RobesColor.ink }
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 9, weight: .medium))
                }
                Text(title.uppercased())
                    .font(RobesType.sans(10, .medium))
                    .tracking(1.2)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                if filled {
                    Capsule().fill(RobesColor.ink)
                } else {
                    Capsule().strokeBorder(RobesColor.line, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// A round action that floats over a photo, so the image keeps the full width.
private struct RailPhotoButton: View {
    let symbol: String
    let label: String

    var body: some View {
        Button {
            // Scheduling and sharing would start here.
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(RobesColor.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(RobesColor.card.opacity(0.92)))
                .overlay(Circle().strokeBorder(RobesColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct RailEmptyState: View {
    let message: String
    var symbol: String = "square.stack"

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(RobesColor.taupe)
            Text(message)
                .font(RobesType.serif(17, .light, italic: true))
                .foregroundStyle(RobesColor.taupe)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Rail — wardrobe & rack") {
    RobesRail()
}

#Preview("Rail — look detail") {
    NavigationStack { RailLookDetail(look: RobesSample.modernClassic) }
}

#Preview("Rail — item detail, in a look") {
    NavigationStack {
        RailItemDetail(item: RobesSample.blackTee, piece: RobesSample.casual.pieces.first)
    }
}

#Preview("Rail — item detail, wishlist") {
    NavigationStack { RailItemDetail(item: RobesSample.waistcoat) }
}
