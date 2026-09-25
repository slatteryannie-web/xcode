import SwiftUI
import CoreText

// MARK: - Palette

extension Color {
    /// Creates a colour from a 0xRRGGBB literal.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// The warm, understated neutral palette shared by every Robes variation.
enum RobesColor {
    static let paper = Color(hex: 0xF1EDE6)      // warm cream — primary canvas
    static let paperLight = Color(hex: 0xFAF8F5) // off-white — secondary surfaces
    static let card = Color(hex: 0xFFFFFF)       // white — raised cards
    static let ink = Color(hex: 0x202021)        // charcoal — primary text

    static let taupe = Color(hex: 0xA89880)      // muted taupe — tertiary text, icons
    static let clay = Color(hex: 0x8C816D)       // clay — labels, secondary text
    static let umber = Color(hex: 0x5F5A4E)      // deep umber — emphasis on light ground

    static let line = Color(hex: 0xE5DED1)       // pale beige — hairline borders
    static let shade = Color(hex: 0xDCD2C0)      // deeper sand — plans, laid over the calendar
    static let blush = Color(hex: 0xF3D2D7)      // dusty blush — accent
    static let sage = Color(hex: 0x8C9A72)       // muted sage — confirmation accent
}

// MARK: - Typography

/// Cormorant (serif, expressive) paired with Inter (sans, interface).
///
/// Neither face ships with iOS. When the family is not installed the closest
/// system face is substituted so layouts stay faithful; dropping the real
/// font files into the target upgrades every call site automatically.
enum RobesType {
    /// Installed font family names, lowercased, resolved once.
    private static let families: Set<String> = {
        let names = CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
        return Set(names.map { $0.lowercased() })
    }()

    private static func installed(_ candidates: [String]) -> String? {
        candidates.first { families.contains($0.lowercased()) }
    }

    private static let cormorant = installed(["Cormorant", "Cormorant Garamond", "Cormorant Infant"])
    private static let inter = installed(["Inter", "Inter Variable", "Inter Tight"])

    /// Headings, look names and expressive copy. Light by default, often italic.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .light, italic: Bool = false) -> Font {
        let base: Font = if let cormorant {
            .custom(cormorant, size: size).weight(weight)
        } else {
            .system(size: size, weight: weight, design: .serif)
        }
        return italic ? base.italic() : base
    }

    /// Body copy and interface elements.
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if let inter {
            .custom(inter, size: size).weight(weight)
        } else {
            .system(size: size, weight: weight, design: .default)
        }
    }
}

/// Small uppercase Inter with generous letter spacing — the editorial label style.
struct MicroLabel: View {
    let text: String
    var color: Color = RobesColor.clay
    var size: CGFloat = 10
    var tracking: CGFloat = 1.6

    init(_ text: String, color: Color = RobesColor.clay, size: CGFloat = 10, tracking: CGFloat = 1.6) {
        self.text = text
        self.color = color
        self.size = size
        self.tracking = tracking
    }

    var body: some View {
        Text(text.uppercased())
            .font(RobesType.sans(size, .medium))
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

/// The Robes wordmark — serif, widely tracked.
struct Wordmark: View {
    var size: CGFloat = 15

    var body: some View {
        Text("ROBES")
            .font(RobesType.serif(size, .regular))
            .tracking(size * 0.34)
            .foregroundStyle(RobesColor.ink)
    }
}

// MARK: - Asset names

/// Placeholder imagery from the project asset catalog.
enum RobesAsset {
    // On-body look renders
    static let lookCasual = "Look1"
    static let lookRedNote = "Look2"
    static let lookDenim = "Look3"
    static let lookClassic = "Look4"
    static let lookTailored = "Look5"

    // Tops & layers
    static let blackTee = "IMG_2977"
    static let sageCrinkleTop = "IMG_2246"
    static let linenTank = "IMG_2316"
    static let whiteLinenBlouse = "IMG_2320"
    static let towelTop = "IMG_2323"
    static let sageLinenShirt = "IMG_2652"
    static let satinBodysuit = "IMG_2648"
    static let waistcoat = "balmain-waistcoat"
    static let suedeJacket = "Screenshot 2026-08-05 at 17.21.00"

    // Bottoms & dresses
    static let satinTrousers = "IMG_2651"
    static let linenTrousers = "IMG_2657"
    static let denimMiniSkirt = "IMG_2654"
    static let redLinenSkirt = "IMG_2315"
    static let navyTrousers = "Screenshot 2026-07-31 at 09.55.14"
    static let printedLeggings = "IMG_2319"
    static let pinkShorts = "IMG_2244"
    static let sageShorts = "IMG_2245"
    static let pinaforeDress = "IMG_2324"
    static let navyCamisole = "IMG_2317"

    // Shoes
    static let salomonRunners = "IMG_2273"
    static let salomonWorn = "IMG_1959"
    static let meshFlats = "IMG_2250"
    static let redConverse = "red cons"
    static let leatherSandals = "Screenshot 2026-07-06 at 09.50.51"

    // Bags & accessories
    static let raffiaTote = "Screenshot 2026-07-06 at 09.54.28"
    static let knitTote = "IMG_2647"
    static let leatherTote = "mixboard-image (4)"
    static let goldEarrings = "Screenshot 2026-07-08 at 16.41.58"
    static let silkScarf = "IMG_2650"
}

// MARK: - Model

enum ItemRole: String, CaseIterable, Hashable {
    case top, layer, bottom, dress, shoes, bag, accessory

    var badge: String { rawValue.uppercased() }

    var plural: String {
        switch self {
        case .top: "Tops"
        case .layer: "Layers"
        case .bottom: "Bottoms"
        case .dress: "Dresses"
        case .shoes: "Shoes"
        case .bag: "Bags"
        case .accessory: "Accessories"
        }
    }

    var symbol: String {
        switch self {
        case .top: "tshirt"
        case .layer: "square.stack"
        case .bottom: "rectangle.portrait"
        case .dress: "figure.dress.line.vertical.figure"
        case .shoes: "shoe"
        case .bag: "handbag"
        case .accessory: "sparkles"
        }
    }
}

/// The four editorial slots a look is composed from.
enum LookSlot: String, CaseIterable, Hashable {
    case canvas = "The Canvas"
    case anchor = "The Anchor"
    case texture = "The Texture"
    case exclamation = "The Exclamation Point"
}

/// How a look entered the app.
enum LookOrigin: Hashable {
    case selfie
    case flatLay
    case prompt(String)
    case link
    case suggested
    /// Shared by another wearer, carrying their name.
    case community(String)

    var label: String {
        switch self {
        case .selfie: "From a mirror selfie"
        case .flatLay: "From a flat lay"
        case .prompt: "From a prompt"
        case .link: "From a link"
        case .suggested: "Suggested by Robes"
        case .community(let name): "Shared by \(name)"
        }
    }

    var symbol: String {
        switch self {
        case .selfie: "person.crop.square"
        case .flatLay: "square.grid.2x2"
        case .prompt: "sparkles"
        case .link: "link"
        case .suggested: "wand.and.stars"
        case .community: "person.2"
        }
    }
}

/// Where a look stands with the wearer.
///
/// A *saved* look is a specific combination they've committed to and want to
/// come back to. A *suggestion* is a draft — the app's proposal, or another
/// wearer's — which they can edit and then save, turning it into a saved look.
enum LookState: Hashable {
    case saved
    case suggestion
}

/// What a look is labelled as wherever looks are listed together. A step finer
/// than `LookState`: an unsaved look reads differently depending on whether
/// Robes proposed it or another wearer did.
enum LookBadge: Hashable {
    case saved
    case suggestion
    case shared

    var label: String {
        switch self {
        case .saved: "Saved"
        case .suggestion: "Suggestion"
        case .shared: "Shared"
        }
    }

    var symbol: String {
        switch self {
        case .saved: "bookmark.fill"
        case .suggestion: "sparkles"
        case .shared: "person.2.fill"
        }
    }
}

struct RobesItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let brand: String
    let role: ItemRole
    let asset: String
    var wears: Int = 0
    var owned: Bool = true
    var price: String? = nil
    var retailer: String? = nil
    /// Automatically applied on capture, editable by the wearer.
    var tags: [String] = []

    var wearLabel: String { wears == 1 ? "1 wear" : "\(wears) wears" }
}

/// An item in the context of a look: which slot it fills and why.
struct LookPiece: Identifiable, Hashable {
    let id = UUID()
    let item: RobesItem
    let slot: LookSlot
    let rationale: String
}

struct RobesLook: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let asset: String
    let note: String
    var tags: [String] = []
    var pieces: [LookPiece] = []
    var origin: LookOrigin = .selfie
    /// Saved by the wearer, or still a draft the app is putting forward.
    var state: LookState = .saved
    var wears: Int = 0
    var lastWorn: String? = nil
    /// When the look was last saved or edited — what "recent" is sorted by.
    var savedOn: Date = .distantPast

    var isSuggested: Bool { state == .suggestion }

    /// The wearer who shared this look, when it came from the community.
    var author: String? {
        if case .community(let name) = origin { return name }
        return nil
    }

    /// Saving wins over provenance: once the wearer keeps a shared look, it's
    /// theirs, and reads as saved.
    var badge: LookBadge {
        if state == .saved { return .saved }
        return author == nil ? .suggestion : .shared
    }

    var savedOnLabel: String {
        savedOn == .distantPast ? "—" : savedOn.formatted(.dateTime.day().month(.abbreviated))
    }

    /// Pieces the wearer doesn't own yet.
    var wishlistPieces: [LookPiece] { pieces.filter { !$0.item.owned } }

    var wishlistCount: Int { wishlistPieces.count }

    /// True when every piece is already in the wardrobe.
    var isWearable: Bool { wishlistCount == 0 }

    var items: [RobesItem] { pieces.map(\.item) }

    func pieces(in slot: LookSlot) -> [LookPiece] { pieces.filter { $0.slot == slot } }
}

/// A look together with the day it belongs to, when it has one. A day's look is
/// either *scheduled* — the wearer assigned it in the plan — or a suggestion
/// Robes is offering to fill an open day.
struct PlannedLook: Identifiable, Hashable {
    let look: RobesLook
    var date: Date? = nil
    /// True when the look is assigned to that day in the plan, false when Robes
    /// is proposing it for a day that's still open.
    var isScheduled: Bool = false

    /// Stable across recomputation, and distinct when one look fills two days.
    var id: String { "\(look.id)-\(date?.timeIntervalSince1970 ?? -1)" }

    /// "Today", "Tomorrow", or the weekday name.
    var dateLabel: String? {
        guard let date else { return nil }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide))
    }
}

/// The shelves the Looks tab is built from. Each one is a rail on the tab and a
/// grid of its own when you tap through.
enum LookCuration: String, CaseIterable, Identifiable, Hashable {
    case saved
    case nextSevenDays
    /// Robes' own proposals, built from the wearer's pieces.
    case ideas
    /// Proposals that came from other wearers.
    case shared

    var id: String { rawValue }

    var title: String {
        switch self {
        case .saved: "Saved Looks"
        case .nextSevenDays: "Next 7 Days"
        case .ideas: "Inspiration"
        case .shared: "Shared by Others"
        }
    }

    /// Only a finite collection the wearer built is worth counting. The day
    /// list is always the same length, and the feeds have no end to count to.
    var showsCount: Bool { self == .saved }

    /// Feeds keep producing looks as you scroll; the other curations are lists.
    var isFeed: Bool { self == .ideas || self == .shared }

    var entries: [PlannedLook] {
        switch self {
        case .saved: RobesSample.savedLooks.map { PlannedLook(look: $0) }
        case .nextSevenDays: RobesSample.nextSevenDays
        case .ideas: RobesSample.ideaLooks.map { PlannedLook(look: $0) }
        case .shared: RobesSample.sharedLooks.map { PlannedLook(look: $0) }
        }
    }
}

// MARK: - Collections

/// Something held in a collection: a whole look, or a single piece. A piece can
/// be one that also appears inside a look, or a loose one.
enum CollectionMember: Identifiable, Hashable {
    case look(RobesLook)
    case item(RobesItem)

    var id: UUID {
        switch self {
        case .look(let look): look.id
        case .item(let item): item.id
        }
    }

    var name: String {
        switch self {
        case .look(let look): look.name
        case .item(let item): item.name
        }
    }

    var asset: String {
        switch self {
        case .look(let look): look.asset
        case .item(let item): item.asset
        }
    }

    var tags: [String] {
        switch self {
        case .look(let look): look.tags
        case .item(let item): item.tags
        }
    }
}

/// A wearer-made grouping of looks and pieces. Anything can belong to any
/// number of collections; a collection is a view onto the wardrobe, not a move.
///
/// A look brings its own pieces in with it — those are in the collection by
/// virtue of the look. `looseItems` is for the other kind: pieces put in on
/// their own, belonging to no look here.
struct RobesCollection: Identifiable, Hashable {
    let id = UUID()
    /// Proposed from the contents when the collection is made, then editable.
    var name: String
    var looks: [RobesLook] = []
    var looseItems: [RobesItem] = []
    var savedOn: Date = .distantPast

    /// Pieces that arrived inside a look, de-duplicated across looks.
    var itemsInLooks: [RobesItem] {
        var seen = Set<UUID>()
        return looks.flatMap(\.items).filter { seen.insert($0.id).inserted }
    }

    /// Loose pieces that genuinely aren't in any of these looks. Derived rather
    /// than trusted, so adding a look that already contains a loose piece can't
    /// leave that piece listed in both places.
    var unassignedItems: [RobesItem] {
        let inLooks = Set(looks.flatMap(\.items).map(\.id))
        return looseItems.filter { !inLooks.contains($0.id) }
    }

    /// Distinct pieces in the collection, however they got here.
    var itemCount: Int {
        Set(itemsInLooks.map(\.id)).union(unassignedItems.map(\.id)).count
    }

    /// Up to four members stand in for the whole collection in its collage.
    var collageMembers: [CollectionMember] {
        let members = looks.map(CollectionMember.look) + unassignedItems.map(CollectionMember.item)
        return Array(members.prefix(4))
    }

    var summary: String {
        let pieces = itemCount
        let parts = [
            looks.isEmpty ? nil : "\(looks.count) \(looks.count == 1 ? "look" : "looks")",
            pieces == 0 ? nil : "\(pieces) \(pieces == 1 ? "piece" : "pieces")"
        ].compactMap { $0 }
        return parts.isEmpty ? "Empty" : parts.joined(separator: " · ")
    }

    /// A piece in the collection together with the looks here that use it.
    ///
    /// This is the relationship a collection is really made of, and the unit its
    /// detail view is built from: one row per piece, however many looks draw on
    /// it, rather than the same piece repeated under every look.
    struct ItemPlacement: Identifiable, Hashable {
        let item: RobesItem
        let looks: [RobesLook]

        var id: UUID { item.id }

        /// In the collection on its own, belonging to none of its looks.
        var isLoose: Bool { looks.isEmpty }
    }

    /// Every distinct piece in the collection, once each, in the order the looks
    /// introduce them, with loose pieces last.
    var placements: [ItemPlacement] {
        var order: [UUID] = []
        var found: [UUID: (item: RobesItem, looks: [RobesLook])] = [:]

        for look in looks {
            for piece in look.pieces {
                let key = piece.item.id
                if found[key] == nil {
                    found[key] = (piece.item, [])
                    order.append(key)
                }
                // A piece filling two slots of one look still lists that look once.
                if found[key]?.looks.contains(where: { $0.id == look.id }) == false {
                    found[key]?.looks.append(look)
                }
            }
        }

        for item in unassignedItems where found[item.id] == nil {
            found[item.id] = (item, [])
            order.append(item.id)
        }

        return order.compactMap { found[$0] }.map {
            ItemPlacement(item: $0.item, looks: $0.looks)
        }
    }

    /// Every distinct piece in the collection, once each.
    var allItems: [RobesItem] { placements.map(\.item) }

    /// Pieces here that belong to none of the collection's looks.
    var loosePlacements: [ItemPlacement] { placements.filter(\.isLoose) }

    /// How many of the collection's looks contain each piece, keyed by piece.
    /// Zero means the piece is in the collection on its own.
    var lookCountByItem: [UUID: Int] {
        Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.looks.count) })
    }

    /// What Robes proposes to call a collection: the tag its contents have most
    /// in common. Ties break alphabetically so the name doesn't wander.
    static func suggestedName(for looks: [RobesLook], items: [RobesItem]) -> String {
        let tags = looks.flatMap(\.tags) + items.flatMap(\.tags)
        let counts = tags.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        let ranked = counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }
        guard let top = ranked.first?.key else { return "New Collection" }
        return "\(top) Edit"
    }
}

// MARK: - Plans

/// One use of a look or a piece inside a plan.
///
/// The same look can be worn on more than one day of a trip, so an instance
/// carries its own identity separate from what it points at — otherwise a
/// duplicate would be indistinguishable from the original.
struct PlanInstance: Identifiable, Hashable {
    let id = UUID()
    let member: CollectionMember

    var name: String { member.name }

    static func look(_ look: RobesLook) -> PlanInstance { PlanInstance(member: .look(look)) }
    static func item(_ item: RobesItem) -> PlanInstance { PlanInstance(member: .item(item)) }

    /// A second use of the same look or piece, with a fresh identity.
    var duplicated: PlanInstance { PlanInstance(member: member) }
}

/// Something happening on a day of a plan — "Flight out", "Black tie ball". A
/// day can hold several, and each dresses separately.
///
/// The title does double duty: it's what the wearer reads, and it's the prompt
/// Robes answers when asked to suggest a look for the event.
struct PlanEvent: Identifiable, Hashable {
    let id = UUID()
    var title: String
    /// Looks and pieces assigned to this event, in the order they'll be worn.
    var entries: [PlanInstance] = []
    /// A look Robes is putting forward for this event, awaiting the wearer's
    /// yes, another try, or dismissal.
    var suggestion: RobesLook? = nil

    var isEmpty: Bool { entries.isEmpty }
}

/// One day inside a plan: the events on it, and anything assigned to the day
/// without belonging to one of them.
struct PlanDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var events: [PlanEvent] = []
    /// Assigned to the day itself rather than to any of its events.
    var entries: [PlanInstance] = []

    /// Everything the day dresses, whichever event it belongs to.
    var allEntries: [PlanInstance] { entries + events.flatMap(\.entries) }

    var isEmpty: Bool { allEntries.isEmpty }

    /// What the calendar shows as the day's heading: its first event.
    var occasion: String? { events.first?.title }

    /// Every piece the day calls for, counting those inside its looks.
    var itemIDs: Set<UUID> {
        var ids = Set<UUID>()
        for entry in allEntries {
            switch entry.member {
            case .look(let look): ids.formUnion(look.items.map(\.id))
            case .item(let item): ids.insert(item.id)
            }
        }
        return ids
    }

    var weekdayShort: String { date.formatted(.dateTime.weekday(.abbreviated)).uppercased() }
    var dayNumber: String { date.formatted(.dateTime.day()) }
    var monthShort: String { date.formatted(.dateTime.month(.abbreviated)).uppercased() }
    var isToday: Bool { Calendar.current.isDateInToday(date) }
}

/// A trip, a weekend away, an event. A plan is a collection — the same looks and
/// loose pieces — with dates laid over it, so what's being brought can be spread
/// across days and checked against what the days are for.
struct RobesPlan: Identifiable, Hashable {
    let id = UUID()
    var name: String
    /// What the plan brings.
    var collection: RobesCollection
    var days: [PlanDay] = []
    /// Looks and pieces the plan is bringing that no day claims yet. These are
    /// what the wearer drags down into the days.
    var unassigned: [PlanInstance] = []

    var startDate: Date? { days.map(\.date).min() }
    var endDate: Date? { days.map(\.date).max() }

    func day(on date: Date) -> PlanDay? {
        days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// True when the date falls inside the plan's range, whether or not that day
    /// has anything assigned.
    func covers(_ date: Date) -> Bool {
        let calendar = Calendar.current
        guard let start = startDate, let end = endDate else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: start) && day <= calendar.startOfDay(for: end)
    }

    /// "12–16 Sep", or a single date when the plan is one day long.
    var dateRangeLabel: String {
        guard let start = startDate, let end = endDate else { return "No dates yet" }
        let day = Date.FormatStyle.dateTime.day()
        let dayMonth = Date.FormatStyle.dateTime.day().month(.abbreviated)

        if Calendar.current.isDate(start, equalTo: end, toGranularity: .day) {
            return start.formatted(dayMonth)
        }
        let sameMonth = Calendar.current.isDate(start, equalTo: end, toGranularity: .month)
        return "\(start.formatted(sameMonth ? day : dayMonth))–\(end.formatted(dayMonth))"
    }

    // -- What a plan has to be able to answer -----------------------------

    /// Days with nothing to wear assigned yet.
    var openDays: [PlanDay] { days.filter(\.isEmpty) }

    /// Days that name an occasion but have nothing assigned — the gaps most
    /// worth pointing at, because the wearer already said what they're doing.
    var unmetOccasions: [PlanDay] { openDays.filter { $0.occasion != nil } }

    var coveredDayCount: Int { days.count - openDays.count }

    /// How many days of the plan each piece is worn on.
    var dayCountByItem: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for day in days {
            for id in day.itemIDs { counts[id, default: 0] += 1 }
        }
        return counts
    }

    /// Distinct looks the plan draws on, however many days they're worn on.
    var lookCount: Int {
        var ids = Set<UUID>()
        for day in days {
            for entry in day.allEntries {
                if case .look(let look) = entry.member { ids.insert(look.id) }
            }
        }
        for entry in unassigned {
            if case .look(let look) = entry.member { ids.insert(look.id) }
        }
        return ids.count
    }

    /// Pieces the plan is bringing, counting those inside its looks.
    var itemCount: Int {
        var ids = Set<UUID>()
        for day in days { ids.formUnion(day.itemIDs) }
        for entry in unassigned {
            switch entry.member {
            case .look(let look): ids.formUnion(look.items.map(\.id))
            case .item(let item): ids.insert(item.id)
            }
        }
        return ids.count
    }

    /// How many pieces accepting a look would add that the plan isn't already
    /// carrying — the cost of taking a suggestion.
    func newItemCount(accepting look: RobesLook) -> Int {
        var carried = Set<UUID>()
        for day in days { carried.formUnion(day.itemIDs) }
        for entry in unassigned {
            switch entry.member {
            case .look(let existing): carried.formUnion(existing.items.map(\.id))
            case .item(let item): carried.insert(item.id)
            }
        }
        return look.items.filter { !carried.contains($0.id) }.count
    }

    /// Pieces being brought that no day calls for — packed weight for nothing.
    var unwornItems: [RobesItem] {
        collection.allItems.filter { (dayCountByItem[$0.id] ?? 0) == 0 }
    }

    /// Pieces worn on more than one day, most repeated first. Repetition isn't
    /// wrong on a trip; it's just worth being able to see.
    var repeatedItems: [(item: RobesItem, days: Int)] {
        let counts = dayCountByItem
        return collection.allItems
            .compactMap { item -> (item: RobesItem, days: Int)? in
                let days = counts[item.id] ?? 0
                return days > 1 ? (item, days) : nil
            }
            .sorted { $0.days > $1.days }
    }
}

/// A day in the planner, with zero or more looks assigned.
struct PlanEntry: Identifiable {
    let id = UUID()
    let date: Date
    var looks: [RobesLook] = []
    var occasion: String? = nil

    var weekdayInitial: String {
        date.formatted(.dateTime.weekday(.narrow))
    }

    var weekdayShort: String {
        date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    var dayNumber: String {
        date.formatted(.dateTime.day())
    }

    var isToday: Bool { Calendar.current.isDateInToday(date) }
}

// MARK: - Capture sources

struct CaptureSource: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
}

enum RobesCapture {
    /// Ways to start a new look.
    static let looks: [CaptureSource] = [
        .init(title: "Mirror selfie", subtitle: "Shoot what you're wearing", symbol: "camera"),
        .init(title: "Camera roll", subtitle: "Lift a look from a photo", symbol: "photo.on.rectangle.angled"),
        .init(title: "Flat lay", subtitle: "Photograph pieces together", symbol: "square.grid.2x2"),
        .init(title: "Describe it", subtitle: "Write a prompt for Robes", symbol: "sparkles"),
        .init(title: "Dropped in", subtitle: "Photos shared from apps", symbol: "tray.and.arrow.down"),
        .init(title: "From a link", subtitle: "Paste a URL", symbol: "link")
    ]

    /// Ways to add a new item.
    static let items: [CaptureSource] = [
        .init(title: "Camera", subtitle: "Lay the piece down and shoot", symbol: "camera"),
        .init(title: "Photos", subtitle: "Pick from your library", symbol: "photo.on.rectangle.angled"),
        .init(title: "From a link", subtitle: "Paste a shop URL", symbol: "link")
    ]
}

// MARK: - Sample content

enum RobesSample {

    // -- Wardrobe ---------------------------------------------------------

    static let blackTee = RobesItem(
        name: "Black long-sleeve t-shirt", brand: "COS", role: .top,
        asset: RobesAsset.blackTee, wears: 12,
        tags: ["Black", "Cotton", "Everyday"]
    )
    static let linenTank = RobesItem(
        name: "Oatmeal linen tank", brand: "Arket", role: .top,
        asset: RobesAsset.linenTank, wears: 8,
        tags: ["Neutral", "Linen", "Summer"]
    )
    static let whiteBlouse = RobesItem(
        name: "White linen blouse", brand: "Totême", role: .top,
        asset: RobesAsset.whiteLinenBlouse, wears: 3,
        tags: ["White", "Linen", "Work"]
    )
    static let sageTop = RobesItem(
        name: "Sage crinkle top", brand: "Baserange", role: .top,
        asset: RobesAsset.sageCrinkleTop, wears: 5,
        tags: ["Green", "Crinkle", "Weekend"]
    )
    static let towelTop = RobesItem(
        name: "Monogram towelling top", brand: "Givenchy", role: .top,
        asset: RobesAsset.towelTop, wears: 1,
        tags: ["Terracotta", "Towelling", "Holiday"]
    )
    static let bodysuit = RobesItem(
        name: "Olive satin bodysuit", brand: "Wolford", role: .top,
        asset: RobesAsset.satinBodysuit, wears: 1,
        tags: ["Olive", "Satin", "Evening"]
    )
    static let sageShirt = RobesItem(
        name: "Sage linen shirt", brand: "The Frankie Shop", role: .layer,
        asset: RobesAsset.sageLinenShirt, wears: 6,
        tags: ["Green", "Linen", "Layer"]
    )
    static let waistcoat = RobesItem(
        name: "Balmain black waistcoat", brand: "Balmain", role: .layer,
        asset: RobesAsset.waistcoat, wears: 0, owned: false,
        price: "€1,295", retailer: "Net-a-Porter",
        tags: ["Black", "Tailoring", "Statement"]
    )
    static let suedeJacket = RobesItem(
        name: "Suede utility jacket", brand: "Massimo Dutti", role: .layer,
        asset: RobesAsset.suedeJacket, wears: 0, owned: false,
        price: "€349", retailer: "Massimo Dutti",
        tags: ["Brown", "Suede", "Autumn"]
    )
    static let satinTrousers = RobesItem(
        name: "Ivory satin wide-leg trousers", brand: "The Frankie Shop", role: .bottom,
        asset: RobesAsset.satinTrousers, wears: 4,
        tags: ["Ivory", "Satin", "Evening"]
    )
    static let linenTrousers = RobesItem(
        name: "Cream linen trousers", brand: "Totême", role: .bottom,
        asset: RobesAsset.linenTrousers, wears: 9,
        tags: ["Cream", "Linen", "Summer"]
    )
    static let denimSkirt = RobesItem(
        name: "Grey denim mini skirt", brand: "Agolde", role: .bottom,
        asset: RobesAsset.denimMiniSkirt, wears: 7,
        tags: ["Grey", "Denim", "Weekend"]
    )
    static let redSkirt = RobesItem(
        name: "Red linen skirt", brand: "Zara", role: .bottom,
        asset: RobesAsset.redLinenSkirt, wears: 2,
        tags: ["Red", "Linen", "Statement"]
    )
    static let navyTrousers = RobesItem(
        name: "Navy tapered trousers", brand: "Arket", role: .bottom,
        asset: RobesAsset.navyTrousers, wears: 0, owned: false,
        price: "€120", retailer: "Arket",
        tags: ["Navy", "Tailoring", "Work"]
    )
    static let leggings = RobesItem(
        name: "Printed leggings", brand: "Sweaty Betty", role: .bottom,
        asset: RobesAsset.printedLeggings, wears: 11,
        tags: ["Print", "Jersey", "Sport"]
    )
    static let pinafore = RobesItem(
        name: "Linen pinafore dress", brand: "COS", role: .dress,
        asset: RobesAsset.pinaforeDress, wears: 3,
        tags: ["Sand", "Linen", "Summer"]
    )
    static let camisole = RobesItem(
        name: "Navy cotton camisole", brand: "Skall Studio", role: .dress,
        asset: RobesAsset.navyCamisole, wears: 2,
        tags: ["Navy", "Cotton", "Holiday"]
    )
    static let runners = RobesItem(
        name: "White Salomon running shoes", brand: "Salomon", role: .shoes,
        asset: RobesAsset.salomonRunners, wears: 14,
        tags: ["White", "Trainer", "Sport"]
    )
    static let meshFlats = RobesItem(
        name: "Embellished mesh flats", brand: "Ancient Greek Sandals", role: .shoes,
        asset: RobesAsset.meshFlats, wears: 4,
        tags: ["Silver", "Mesh", "Evening"]
    )
    static let converse = RobesItem(
        name: "Red Converse high tops", brand: "Converse", role: .shoes,
        asset: RobesAsset.redConverse, wears: 0, owned: false,
        price: "€75", retailer: "Converse",
        tags: ["Red", "Canvas", "Weekend"]
    )
    static let sandals = RobesItem(
        name: "Tan leather heeled sandals", brand: "Souliers Martinez", role: .shoes,
        asset: RobesAsset.leatherSandals, wears: 0, owned: false,
        price: "€290", retailer: "Mytheresa",
        tags: ["Tan", "Leather", "Summer"]
    )
    static let knitTote = RobesItem(
        name: "Woven knit tote", brand: "Marram", role: .bag,
        asset: RobesAsset.knitTote, wears: 6,
        tags: ["Straw", "Woven", "Summer"]
    )
    static let raffiaTote = RobesItem(
        name: "Raffia logo tote", brand: "Loewe", role: .bag,
        asset: RobesAsset.raffiaTote, wears: 0, owned: false,
        price: "€650", retailer: "Net-a-Porter",
        tags: ["Straw", "Raffia", "Holiday"]
    )
    static let leatherTote = RobesItem(
        name: "Structured leather tote", brand: "Polène", role: .bag,
        asset: RobesAsset.leatherTote, wears: 0, owned: false,
        price: "€420", retailer: "Polène",
        tags: ["Tan", "Leather", "Work"]
    )
    static let earrings = RobesItem(
        name: "Gold fan earrings", brand: "Sophie Buhai", role: .accessory,
        asset: RobesAsset.goldEarrings, wears: 5,
        tags: ["Gold", "Statement", "Evening"]
    )
    static let scarf = RobesItem(
        name: "Printed silk scarf", brand: "Faliero Sarti", role: .accessory,
        asset: RobesAsset.silkScarf, wears: 2,
        tags: ["Teal", "Silk", "Layer"]
    )
    static let pinkShorts = RobesItem(
        name: "Pink sport shorts", brand: "Adidas", role: .bottom,
        asset: RobesAsset.pinkShorts, wears: 3,
        tags: ["Pink", "Jersey", "Sport"]
    )
    static let sageShorts = RobesItem(
        name: "Sage sport shorts", brand: "Adidas", role: .bottom,
        asset: RobesAsset.sageShorts, wears: 4,
        tags: ["Green", "Jersey", "Sport"]
    )

    static let allItems: [RobesItem] = [
        blackTee, linenTank, whiteBlouse, sageTop, towelTop, bodysuit,
        sageShirt, waistcoat, suedeJacket,
        satinTrousers, linenTrousers, denimSkirt, redSkirt, navyTrousers,
        leggings, pinkShorts, sageShorts,
        pinafore, camisole,
        runners, meshFlats, converse, sandals,
        knitTote, raffiaTote, leatherTote,
        earrings, scarf
    ]

    static var ownedItems: [RobesItem] { allItems.filter(\.owned) }
    static var suggestedItems: [RobesItem] { allItems.filter { !$0.owned } }

    static func ownedItems(role: ItemRole) -> [RobesItem] {
        ownedItems.filter { $0.role == role }
    }

    /// Roles that actually have owned pieces, in display order.
    static var populatedRoles: [ItemRole] {
        ItemRole.allCases.filter { !ownedItems(role: $0).isEmpty }
    }

    // -- Looks ------------------------------------------------------------

    /// Sample timestamps are relative, so the curations stay plausible whenever
    /// the app is run.
    private static func daysAgo(_ days: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    static let casual = RobesLook(
        name: "Casual",
        asset: RobesAsset.lookCasual,
        note: "Black long-sleeve with the ribbed leggings and white runners — the uniform for a day that keeps moving.",
        tags: ["Lounge", "Everyday", "Sporty"],
        pieces: [
            LookPiece(item: blackTee, slot: .canvas,
                      rationale: "Skims the body, so nothing fights the leggings."),
            LookPiece(item: leggings, slot: .anchor,
                      rationale: "High-waisted and unbroken from waist to ankle."),
            LookPiece(item: runners, slot: .texture,
                      rationale: "Breaks up the black with a clean white base."),
            LookPiece(item: scarf, slot: .exclamation,
                      rationale: "Knotted at the throat for a little colour.")
        ],
        origin: .selfie,
        state: .saved,
        wears: 2,
        lastWorn: "24 Aug",
        savedOn: daysAgo(3)
    )

    static let redNote = RobesLook(
        name: "Red Note",
        asset: RobesAsset.lookRedNote,
        note: "One saturated piece against oatmeal linen. The rest of the look stays quiet so the red can speak.",
        tags: ["Weekend", "Summer", "Colour"],
        pieces: [
            LookPiece(item: linenTank, slot: .canvas,
                      rationale: "Warm neutral ground that flatters the red."),
            LookPiece(item: redSkirt, slot: .anchor,
                      rationale: "The whole point of the look — worn high and loose."),
            LookPiece(item: sandals, slot: .texture,
                      rationale: "Tan leather bridges the linen and the red."),
            LookPiece(item: knitTote, slot: .exclamation,
                      rationale: "Woven texture keeps it from reading too styled.")
        ],
        origin: .prompt("something with one loud colour for a warm Saturday"),
        state: .saved,
        wears: 1,
        lastWorn: "16 Aug",
        savedOn: daysAgo(11)
    )

    static let denimEase = RobesLook(
        name: "Denim Ease",
        asset: RobesAsset.lookDenim,
        note: "Soft layers over pale denim. Meant to be thrown on and forgotten about.",
        tags: ["Everyday", "Layered", "Travel"],
        pieces: [
            LookPiece(item: linenTank, slot: .canvas,
                      rationale: "Close-fitting base under the open shirt."),
            LookPiece(item: linenTrousers, slot: .anchor,
                      rationale: "Relaxed leg, cropped just above the ankle."),
            LookPiece(item: sageShirt, slot: .texture,
                      rationale: "Worn open, adding a soft vertical line."),
            LookPiece(item: runners, slot: .exclamation,
                      rationale: "Keeps the whole thing walkable.")
        ],
        origin: .flatLay,
        state: .saved,
        wears: 0,
        lastWorn: nil,
        savedOn: daysAgo(32)
    )

    static let modernClassic = RobesLook(
        name: "Modern Classic",
        asset: RobesAsset.lookClassic,
        note: "A sharp, modern classic — the architectural line of the waistcoat over a clean canvas, with fluid fabrics keeping it nonchalant.",
        tags: ["Everyday", "Work", "Chic"],
        pieces: [
            LookPiece(item: blackTee, slot: .canvas,
                      rationale: "Tucked neatly for a streamlined foundation."),
            LookPiece(item: denimSkirt, slot: .anchor,
                      rationale: "Worn high on the waist to elongate the leg."),
            LookPiece(item: waistcoat, slot: .texture,
                      rationale: "Worn open, creating a long clean line over the torso."),
            LookPiece(item: leatherTote, slot: .exclamation,
                      rationale: "Carried by the top handle — polished hardware.")
        ],
        // Robes proposed it; putting it in the plan is what saved it.
        origin: .suggested,
        state: .saved,
        wears: 0,
        lastWorn: nil,
        savedOn: daysAgo(5)
    )

    static let tailored = RobesLook(
        name: "The Tailored One",
        asset: RobesAsset.lookTailored,
        note: "Long jacket, quiet shirt, trousers that move. Dressed without looking like you tried.",
        tags: ["Work", "Evening", "Chic"],
        pieces: [
            LookPiece(item: whiteBlouse, slot: .canvas,
                      rationale: "Crisp and undone at the collar."),
            LookPiece(item: navyTrousers, slot: .anchor,
                      rationale: "Tapered so the jacket reads longer."),
            LookPiece(item: meshFlats, slot: .texture,
                      rationale: "A flat that still feels like evening."),
            LookPiece(item: earrings, slot: .exclamation,
                      rationale: "The only shine in the look.")
        ],
        origin: .suggested,
        state: .saved,
        wears: 0,
        lastWorn: nil,
        savedOn: daysAgo(6)
    )

    static let offDuty = RobesLook(
        name: "Off Duty",
        asset: RobesAsset.lookDenim,
        note: "Assembled from the three things you reach for most. Nothing here needs thinking about.",
        tags: ["Weekend", "Sporty", "Everyday"],
        pieces: [
            LookPiece(item: linenTank, slot: .canvas,
                      rationale: "The softest thing on the shelf."),
            LookPiece(item: sageShorts, slot: .anchor,
                      rationale: "Cut short enough to keep moving."),
            LookPiece(item: runners, slot: .texture,
                      rationale: "Already your most-worn shoe."),
            LookPiece(item: knitTote, slot: .exclamation,
                      rationale: "Holds more than it looks like it does.")
        ],
        origin: .suggested,
        state: .suggestion,
        savedOn: daysAgo(1)
    )

    static let quietOffice = RobesLook(
        name: "Quiet Office",
        asset: RobesAsset.lookClassic,
        note: "The blouse you under-wear, with the trousers you forget you own. One earring's worth of shine.",
        tags: ["Work", "Chic", "Everyday"],
        pieces: [
            LookPiece(item: whiteBlouse, slot: .canvas,
                      rationale: "Ironed once, worn three times."),
            LookPiece(item: linenTrousers, slot: .anchor,
                      rationale: "Loose enough to sit in all day."),
            LookPiece(item: meshFlats, slot: .texture,
                      rationale: "Quieter than a heel, sharper than a trainer."),
            LookPiece(item: earrings, slot: .exclamation,
                      rationale: "The only thing that catches light.")
        ],
        origin: .suggested,
        state: .suggestion,
        savedOn: daysAgo(2)
    )

    static let earlyStart = RobesLook(
        name: "Early Start",
        asset: RobesAsset.lookCasual,
        note: "The leggings and the black tee, but with the shirt over the top so it survives the walk in.",
        tags: ["Everyday", "Sporty", "Layered"],
        pieces: [
            LookPiece(item: blackTee, slot: .canvas,
                      rationale: "Long sleeves, so no jacket needed."),
            LookPiece(item: leggings, slot: .anchor,
                      rationale: "Your most-worn bottom, by a distance."),
            LookPiece(item: sageShirt, slot: .texture,
                      rationale: "Open, for the ten minutes it's cold."),
            LookPiece(item: runners, slot: .exclamation,
                      rationale: "The only shoe you'd walk that far in.")
        ],
        origin: .suggested,
        state: .suggestion,
        savedOn: daysAgo(5)
    )

    static let softEvening = RobesLook(
        name: "Soft Evening",
        asset: RobesAsset.lookTailored,
        note: "Satin trousers doing the work, with the towelling top keeping it from feeling like an occasion.",
        tags: ["Evening", "Chic", "Summer"],
        pieces: [
            LookPiece(item: towelTop, slot: .canvas,
                      rationale: "Texture against the satin below."),
            LookPiece(item: satinTrousers, slot: .anchor,
                      rationale: "Worn once — it's owed another outing."),
            LookPiece(item: meshFlats, slot: .texture,
                      rationale: "Enough shine without a heel."),
            LookPiece(item: earrings, slot: .exclamation,
                      rationale: "Gold picks up the terracotta.")
        ],
        origin: .suggested,
        state: .suggestion,
        savedOn: daysAgo(3)
    )

    static let printedRun = RobesLook(
        name: "Printed Run",
        asset: RobesAsset.lookDenim,
        note: "Two pieces you only ever wear separately. Robes thinks they hold together.",
        tags: ["Sporty", "Weekend", "Colour"],
        pieces: [
            LookPiece(item: sageTop, slot: .canvas,
                      rationale: "Crinkle stops the leggings reading as gym kit."),
            LookPiece(item: leggings, slot: .anchor,
                      rationale: "The print does all the talking."),
            LookPiece(item: runners, slot: .texture,
                      rationale: "White grounds the whole thing."),
            LookPiece(item: knitTote, slot: .exclamation,
                      rationale: "Big enough for a change of shoes.")
        ],
        origin: .suggested,
        state: .suggestion,
        savedOn: daysAgo(4)
    )

    static let sundayPinafore = RobesLook(
        name: "Sunday Pinafore",
        asset: RobesAsset.lookRedNote,
        note: "The pinafore over the tank, which is how you've worn it twice and forgotten both times.",
        tags: ["Weekend", "Summer", "Layered"],
        pieces: [
            LookPiece(item: linenTank, slot: .canvas,
                      rationale: "Straps sit inside the pinafore's."),
            LookPiece(item: pinafore, slot: .anchor,
                      rationale: "Sand linen, so nothing clashes."),
            LookPiece(item: meshFlats, slot: .texture,
                      rationale: "Flat, silver, unbothered."),
            LookPiece(item: scarf, slot: .exclamation,
                      rationale: "Tied to the tote handle, not the neck.")
        ],
        origin: .suggested,
        state: .suggestion,
        savedOn: daysAgo(6)
    )

    // Community looks — other wearers, built from pieces close to yours.

    static let cityLinen = RobesLook(
        name: "City Linen",
        asset: RobesAsset.lookRedNote,
        note: "Cream on cream, broken by one tan leather note. Two pieces you'd have to buy.",
        tags: ["Summer", "Chic", "Work"],
        pieces: [
            LookPiece(item: whiteBlouse, slot: .canvas,
                      rationale: "Sleeves pushed to the elbow."),
            LookPiece(item: linenTrousers, slot: .anchor,
                      rationale: "Pressed flat down the front."),
            LookPiece(item: sandals, slot: .texture,
                      rationale: "A low heel that survives cobbles."),
            LookPiece(item: leatherTote, slot: .exclamation,
                      rationale: "Structured, so the linen reads deliberate.")
        ],
        origin: .community("Marta L."),
        state: .suggestion,
        savedOn: daysAgo(4)
    )

    static let eveningOlive = RobesLook(
        name: "Evening Olive",
        asset: RobesAsset.lookTailored,
        note: "Satin against satin, with the waistcoat doing the tailoring. Saved from a night out in Lisbon.",
        tags: ["Evening", "Colour", "Chic"],
        pieces: [
            LookPiece(item: bodysuit, slot: .canvas,
                      rationale: "Olive reads warmer than black at night."),
            LookPiece(item: satinTrousers, slot: .anchor,
                      rationale: "Ivory lifts the olive rather than muting it."),
            LookPiece(item: waistcoat, slot: .texture,
                      rationale: "Buttoned, so it works as the top half."),
            LookPiece(item: meshFlats, slot: .exclamation,
                      rationale: "Flat, because the trousers are long.")
        ],
        origin: .community("Ines R."),
        state: .suggestion,
        savedOn: daysAgo(8)
    )

    static let weekendRed = RobesLook(
        name: "Weekend Red",
        asset: RobesAsset.lookCasual,
        note: "The red skirt with canvas instead of leather. Less considered, more wearable.",
        tags: ["Weekend", "Colour", "Summer"],
        pieces: [
            LookPiece(item: blackTee, slot: .canvas,
                      rationale: "Tucked in, sleeves shoved up."),
            LookPiece(item: redSkirt, slot: .anchor,
                      rationale: "The loudest thing either of you owns."),
            LookPiece(item: converse, slot: .texture,
                      rationale: "Matching the skirt on purpose."),
            LookPiece(item: knitTote, slot: .exclamation,
                      rationale: "Straw stops it looking like a costume.")
        ],
        origin: .community("Dervla K."),
        state: .suggestion,
        savedOn: daysAgo(14)
    )

    static let deskToDinner = RobesLook(
        name: "Desk to Dinner",
        asset: RobesAsset.lookClassic,
        note: "Waistcoat on for the meeting, off for the wine. Shared by someone with your exact trousers.",
        tags: ["Work", "Evening", "Chic"],
        pieces: [
            LookPiece(item: whiteBlouse, slot: .canvas,
                      rationale: "Holds a crease all day."),
            LookPiece(item: navyTrousers, slot: .anchor,
                      rationale: "Navy reads sharper than black under office light."),
            LookPiece(item: waistcoat, slot: .texture,
                      rationale: "The layer that changes the whole register."),
            LookPiece(item: sandals, slot: .exclamation,
                      rationale: "A heel you can still stand in at nine.")
        ],
        origin: .community("Aoife B."),
        state: .suggestion,
        savedOn: daysAgo(6)
    )

    static let marketMorning = RobesLook(
        name: "Market Morning",
        asset: RobesAsset.lookDenim,
        note: "Denim skirt, big tote, nothing precious. Posted from a Saturday in Copenhagen.",
        tags: ["Weekend", "Everyday", "Summer"],
        pieces: [
            LookPiece(item: linenTank, slot: .canvas,
                      rationale: "Tucked, so the waistband shows."),
            LookPiece(item: denimSkirt, slot: .anchor,
                      rationale: "Grey denim instead of blue — quieter."),
            LookPiece(item: converse, slot: .texture,
                      rationale: "Red against grey, deliberately."),
            LookPiece(item: raffiaTote, slot: .exclamation,
                      rationale: "Carries a week of vegetables.")
        ],
        origin: .community("Sofie H."),
        state: .suggestion,
        savedOn: daysAgo(10)
    )

    // Assets are reused across the sample looks; spread the repeats so two
    // neighbours in a sorted rail never show the same photo.
    static let terracottaNight = RobesLook(
        name: "Terracotta Night",
        asset: RobesAsset.lookTailored,
        note: "Towelling against satin. Not an obvious pairing until you see it worn.",
        tags: ["Evening", "Colour", "Holiday"],
        pieces: [
            LookPiece(item: towelTop, slot: .canvas,
                      rationale: "The texture is the whole idea."),
            LookPiece(item: satinTrousers, slot: .anchor,
                      rationale: "Ivory keeps the terracotta warm, not loud."),
            LookPiece(item: sandals, slot: .texture,
                      rationale: "Tan sits between the two."),
            LookPiece(item: earrings, slot: .exclamation,
                      rationale: "Gold, to finish it.")
        ],
        origin: .community("Rae M."),
        state: .suggestion,
        savedOn: daysAgo(16)
    )

    static let allLooks: [RobesLook] = [
        casual, redNote, denimEase, modernClassic, tailored,
        offDuty, quietOffice, earlyStart, softEvening, printedRun, sundayPinafore,
        cityLinen, eveningOlive, weekendRed, deskToDinner, marketMorning, terracottaNight
    ]

    /// Kept combinations, most recently saved or edited first.
    static var savedLooks: [RobesLook] {
        allLooks.filter { $0.state == .saved }.sorted { $0.savedOn > $1.savedOn }
    }

    static var suggestedLooks: [RobesLook] { allLooks.filter(\.isSuggested) }

    /// Suggestions Robes built from the wearer's own pieces.
    static var ideaLooks: [RobesLook] {
        allLooks.filter { $0.isSuggested && $0.author == nil }
            .sorted { $0.savedOn > $1.savedOn }
    }

    /// Suggestions shared by other wearers.
    static var sharedLooks: [RobesLook] {
        allLooks.filter { $0.author != nil }.sorted { $0.savedOn > $1.savedOn }
    }

    /// Today plus the seven days ahead, each with whatever is on the calendar
    /// for it, or a suggestion when the day is still open.
    static var nextSevenDays: [PlannedLook] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0...7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }

        // Don't propose a look the wearer has already scheduled in this window.
        let scheduled = Set(days.flatMap { plannedLooks(on: $0) }.map(\.id))
        var pool = (ideaLooks + savedLooks).filter { !scheduled.contains($0.id) }

        return days.flatMap { day -> [PlannedLook] in
            let assigned = plannedLooks(on: day)
            guard assigned.isEmpty else {
                return assigned.map { PlannedLook(look: $0, date: day, isScheduled: true) }
            }
            guard !pool.isEmpty else { return [] }
            return [PlannedLook(look: pool.removeFirst(), date: day)]
        }
    }

    /// Every tag used across looks, for filter rows.
    static var lookTags: [String] {
        Array(Set(allLooks.flatMap(\.tags))).sorted()
    }

    // -- Collections ------------------------------------------------------

    /// Pieces only — nothing here belongs to a look yet.
    static let considering = RobesCollection(
        name: "Considering",
        looseItems: [waistcoat, suedeJacket, sandals, leatherTote, raffiaTote, navyTrousers],
        savedOn: daysAgo(1)
    )

    static let backToTheOffice = RobesCollection(
        name: "Back to the Office",
        looks: [modernClassic, tailored, quietOffice],
        looseItems: [sageShirt, suedeJacket, scarf],
        savedOn: daysAgo(3)
    )

    static let holidayPacking = RobesCollection(
        name: "Holiday Packing",
        looks: [redNote, denimEase],
        looseItems: [towelTop, camisole, pinafore, raffiaTote],
        savedOn: daysAgo(7)
    )

    static let redThread = RobesCollection(
        name: "Red Thread",
        looks: [redNote, weekendRed],
        looseItems: [towelTop],
        savedOn: daysAgo(15)
    )

    /// Most recently made or edited first, like the saved looks.
    static var collections: [RobesCollection] {
        [considering, backToTheOffice, holidayPacking, redThread]
            .sorted { $0.savedOn > $1.savedOn }
    }

    // -- Plans ------------------------------------------------------------

    private static func daysAhead(_ days: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: Date())) ?? Date()
    }

    /// A trip: some days settled, one still open, and a couple of pieces packed
    /// that nothing calls for yet.
    static let lisbon = RobesPlan(
        name: "Lisbon",
        collection: RobesCollection(
            name: "Lisbon",
            looks: [redNote, denimEase],
            looseItems: [towelTop, camisole, pinafore, meshFlats, raffiaTote],
            savedOn: daysAgo(2)
        ),
        days: [
            PlanDay(date: daysAhead(10), events: [
                PlanEvent(title: "Flight out", entries: [.look(denimEase)])
            ]),
            PlanDay(date: daysAhead(11), events: [
                PlanEvent(title: "Beach day", entries: [.item(camisole), .item(pinafore)])
            ]),
            // Two events on one day, each dressed separately.
            PlanDay(date: daysAhead(12), events: [
                PlanEvent(title: "Dinner in Alfama", entries: [.look(redNote)]),
                PlanEvent(title: "Drinks after", entries: [.item(meshFlats)])
            ]),
            PlanDay(date: daysAhead(13), events: [
                PlanEvent(title: "Day trip to Sintra")
            ]),
            PlanDay(date: daysAhead(14), events: [
                PlanEvent(title: "Flight home", entries: [.look(denimEase)])
            ])
        ],
        unassigned: [.item(towelTop), .item(raffiaTote)]
    )

    static let weddingWeekend = RobesPlan(
        name: "Wedding weekend",
        collection: RobesCollection(
            name: "Wedding weekend",
            looks: [tailored, modernClassic],
            looseItems: [bodysuit, satinTrousers, scarf, sandals],
            savedOn: daysAgo(5)
        ),
        days: [
            PlanDay(date: daysAhead(24), events: [
                PlanEvent(title: "Rehearsal dinner", entries: [.look(modernClassic)])
            ]),
            PlanDay(date: daysAhead(25), events: [
                PlanEvent(title: "Black tie ball",
                          entries: [.item(bodysuit), .item(satinTrousers), .item(sandals)])
            ]),
            PlanDay(date: daysAhead(26), events: [
                PlanEvent(title: "Brunch")
            ])
        ],
        unassigned: [.look(tailored), .item(scarf)]
    )

    /// A plan doesn't have to be a trip. An evening out is a one-day plan, and
    /// gets the same treatment on the calendar — its name is the occasion.
    private static func occasionPlan(
        _ name: String,
        offset: Int,
        looks: [RobesLook],
        spanning span: Int = 1
    ) -> RobesPlan {
        let dates = (0..<span).map { weekDay(offset + $0) }
        return RobesPlan(
            name: name,
            collection: RobesCollection(name: name, looks: looks, savedOn: daysAgo(2)),
            days: dates.enumerated().map { index, date in
                // A one-off's event is the plan itself, so the calendar and the
                // detail view both have something to head the day with.
                PlanDay(date: date, events: [
                    PlanEvent(
                        title: name,
                        entries: index < looks.count ? [.look(looks[index])] : []
                    )
                ])
            }
        )
    }

    static let deskDay = occasionPlan("Desk day", offset: 0, looks: [casual])
    static let clientLunch = occasionPlan("Client lunch", offset: 1, looks: [modernClassic])
    static let dinnerOut = occasionPlan("Dinner, 8pm", offset: 4, looks: [tailored])
    static let weekendAway = occasionPlan("Weekend away", offset: 5, looks: [denimEase, casual], spanning: 2)
    static let studioVisit = occasionPlan("Studio visit", offset: 8, looks: [redNote])

    static var plans: [RobesPlan] {
        [deskDay, clientLunch, dinnerOut, weekendAway, studioVisit, lisbon, weddingWeekend].sorted {
            ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture)
        }
    }

    /// The plan whose range covers a date, if any. What lets the calendar draw a
    /// trip as one continuous run rather than a series of unrelated days.
    static func plan(covering date: Date) -> RobesPlan? {
        plans.first { $0.covers(date) }
    }

    // -- Planner ----------------------------------------------------------

    /// Looks assigned straight to a day, with no plan around them — keyed by
    /// offset from the Monday of the current week. An occasion belongs to a
    /// plan, so anything with one lives in `plans` instead.
    private static let planAssignments: [Int: [RobesLook]] = [
        3: [redNote],
        10: [casual],
        12: [denimEase]
    ]

    static var weekStart: Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? calendar.startOfDay(for: today)
    }

    /// A date at an offset from the Monday of the current week.
    static func weekDay(_ offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
    }

    private static func planOffset(for date: Date) -> Int? {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: weekStart, to: calendar.startOfDay(for: date)).day
    }

    /// The looks the wearer has assigned to a given day.
    ///
    /// Putting a look on the calendar commits to it, so anything here is a saved
    /// look by definition — a suggestion is saved the moment it's assigned.
    /// Enforced here so no caller can show a scheduled suggestion.
    static func plannedLooks(on date: Date) -> [RobesLook] {
        guard let offset = planOffset(for: date) else { return [] }
        return (planAssignments[offset] ?? []).map { look in
            var assigned = look
            assigned.state = .saved
            return assigned
        }
    }

    /// Seven days starting from the Monday of the current week.
    static var week: [PlanEntry] {
        let calendar = Calendar.current
        let start = weekStart

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return PlanEntry(date: date, looks: looks(on: date), occasion: occasion(on: date))
        }
    }

    /// An occasion belongs to a plan, so a day's occasion is whatever the plan
    /// covering it is called. Kept for the Atelier and Studio variations, which
    /// still read the week through `PlanEntry`.
    static func occasion(on date: Date) -> String? {
        guard let plan = plan(covering: date) else { return nil }
        return plan.day(on: date)?.occasion ?? plan.name
    }

    /// Every look on a date, whether it came from a plan or was assigned loose.
    static func looks(on date: Date) -> [RobesLook] {
        let fromPlan = plan(covering: date)?.day(on: date)?.entries
            .compactMap { entry -> RobesLook? in
                if case .look(let look) = entry.member { return look }
                return nil
            } ?? []
        return fromPlan + plannedLooks(on: date)
    }

    /// A calendar month grid (leading blanks included) for the month containing `date`.
    static func monthGrid(for date: Date = Date()) -> [PlanEntry?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let dayCount = calendar.range(of: .day, in: .month, for: date)?.count
        else { return [] }

        let first = monthInterval.start
        // Monday-first grid
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        let assignments: [Int: [RobesLook]] = [
            4: [casual],
            7: [modernClassic],
            11: [redNote],
            12: [tailored],
            18: [denimEase],
            19: [casual, redNote],
            25: [modernClassic],
            26: [tailored]
        ]

        let blanks: [PlanEntry?] = Array(repeating: nil, count: leading)
        let days: [PlanEntry?] = (0..<dayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: first) else { return nil }
            let number = calendar.component(.day, from: day)
            return PlanEntry(date: day, looks: assignments[number] ?? [])
        }
        return blanks + days
    }

    static var monthTitle: String {
        Date().formatted(.dateTime.month(.wide).year())
    }

    /// The greeting strip shown at the top of each variation.
    static var weatherLine: String {
        let day = Date().formatted(.dateTime.weekday(.wide))
        return "\(day) · Dublin · 18°"
    }
}
