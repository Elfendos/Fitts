import SwiftUI

/// Simple geometric (non-photorealistic, no human figure) front/back body
/// diagram used by MuscleMapView — each region is a plain shape (circle,
/// capsule, rounded rectangle) colored by how much it was trained. Regions
/// map 1:1 to `PrimaryMuscle`'s body-relevant cases; `.cardio`/`.hiit`/
/// `.mobility` have no fixed body location and are summarized separately
/// as text below the diagram (see MuscleMapView).
struct BodyDiagramView: View {
    enum Side { case front, back }

    let side: Side
    /// Fill color for a given region, already reflecting activation level.
    let colorFor: (PrimaryMuscle) -> Color

    private let neutral = Color(hex: "E5E5EA")
    private let outline = Color(hex: "B8B8C0")

    var body: some View {
        ZStack {
            // Head + neck (decorative — not a trainable region)
            part(.circle, size: 32, center: CGPoint(x: 75, y: 18), color: neutral)
            part(.roundedRect(4), size: CGSize(width: 12, height: 10), center: CGPoint(x: 75, y: 36), color: neutral)

            switch side {
            case .front:
                frontTorsoAndLimbs
            case .back:
                backTorsoAndLimbs
            }
        }
        .frame(width: 150, height: 300)
    }

    // MARK: - Front

    private var frontTorsoAndLimbs: some View {
        Group {
            // Shoulders
            part(.circle, size: 20, center: CGPoint(x: 40, y: 50), color: colorFor(.shoulders))
            part(.circle, size: 20, center: CGPoint(x: 110, y: 50), color: colorFor(.shoulders))

            // Chest
            part(.roundedRect(16), size: CGSize(width: 62, height: 46), center: CGPoint(x: 75, y: 70), color: colorFor(.chest))

            // Core
            part(.roundedRect(14), size: CGSize(width: 48, height: 50), center: CGPoint(x: 75, y: 122), color: colorFor(.core))

            // Upper arms (biceps)
            part(.capsule, size: CGSize(width: 18, height: 55), center: CGPoint(x: 28, y: 90), color: colorFor(.biceps))
            part(.capsule, size: CGSize(width: 18, height: 55), center: CGPoint(x: 122, y: 90), color: colorFor(.biceps))

            // Forearms (decorative)
            part(.capsule, size: CGSize(width: 14, height: 55), center: CGPoint(x: 24, y: 148), color: neutral)
            part(.capsule, size: CGSize(width: 14, height: 55), center: CGPoint(x: 126, y: 148), color: neutral)

            legs
        }
    }

    // MARK: - Back

    private var backTorsoAndLimbs: some View {
        Group {
            part(.circle, size: 20, center: CGPoint(x: 40, y: 50), color: colorFor(.shoulders))
            part(.circle, size: 20, center: CGPoint(x: 110, y: 50), color: colorFor(.shoulders))

            // Whole back (upper+lower merged — PrimaryMuscle.back is one bucket)
            part(.roundedRect(16), size: CGSize(width: 62, height: 96), center: CGPoint(x: 75, y: 96), color: colorFor(.back))

            // Upper arms (triceps, back of arm)
            part(.capsule, size: CGSize(width: 18, height: 55), center: CGPoint(x: 28, y: 90), color: colorFor(.triceps))
            part(.capsule, size: CGSize(width: 18, height: 55), center: CGPoint(x: 122, y: 90), color: colorFor(.triceps))

            part(.capsule, size: CGSize(width: 14, height: 55), center: CGPoint(x: 24, y: 148), color: neutral)
            part(.capsule, size: CGSize(width: 14, height: 55), center: CGPoint(x: 126, y: 148), color: neutral)

            legs
        }
    }

    // MARK: - Shared (legs are one PrimaryMuscle bucket front & back)

    private var legs: some View {
        Group {
            part(.capsule, size: CGSize(width: 24, height: 70), center: CGPoint(x: 58, y: 192), color: colorFor(.legs))
            part(.capsule, size: CGSize(width: 24, height: 70), center: CGPoint(x: 92, y: 192), color: colorFor(.legs))
            part(.capsule, size: CGSize(width: 18, height: 65), center: CGPoint(x: 58, y: 257), color: colorFor(.legs))
            part(.capsule, size: CGSize(width: 18, height: 65), center: CGPoint(x: 92, y: 257), color: colorFor(.legs))
        }
    }

    // MARK: - Shape helper

    private enum PartShape {
        case circle
        case capsule
        case roundedRect(CGFloat)
    }

    @ViewBuilder
    private func part(_ shape: PartShape, size: CGSize, center: CGPoint, color: Color) -> some View {
        Group {
            switch shape {
            case .circle:
                Circle().fill(color).overlay(Circle().stroke(outline, lineWidth: 1.5))
            case .capsule:
                Capsule().fill(color).overlay(Capsule().stroke(outline, lineWidth: 1.5))
            case .roundedRect(let radius):
                RoundedRectangle(cornerRadius: radius).fill(color)
                    .overlay(RoundedRectangle(cornerRadius: radius).stroke(outline, lineWidth: 1.5))
            }
        }
        .frame(width: size.width, height: size.height)
        .position(center)
    }

    private func part(_ shape: PartShape, size: CGFloat, center: CGPoint, color: Color) -> some View {
        part(shape, size: CGSize(width: size, height: size), center: center, color: color)
    }
}
