import SwiftUI

/// Interpolates the physical assembly itself, including the headshell.
struct TonearmDrawing: View, Animatable {
    var size: CGSize
    var recordDiameter: CGFloat
    var recordTop: CGFloat
    nonisolated var parkProgress: CGFloat
    nonisolated var browsePosition: CGFloat

    nonisolated var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(parkProgress, browsePosition) }
        set { parkProgress = newValue.first; browsePosition = newValue.second }
    }

    var body: some View {
        let geometry = TonearmAssemblyLayout.geometry(
            in: size, recordDiameter: recordDiameter, recordTop: recordTop,
            parkProgress: parkProgress, browseOffset: browsePosition
        )
            Canvas { context, _ in
                var assembly = Path()
                assembly.move(to: geometry.pivot)
                assembly.addQuadCurve(to: geometry.headAnchor, control: geometry.control)
                assembly.addLine(to: geometry.stylusTip)
                context.stroke(
                    assembly,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: geometry.pivot.x - 24,
                        y: geometry.pivot.y - 24,
                        width: 48,
                        height: 48
                    )),
                    with: .color(.white)
                )
                var headshell = Path()
                headshell.move(to: geometry.headshellStart)
                headshell.addLine(to: geometry.headshellEnd)
                context.stroke(
                    headshell,
                    with: .color(.white),
                    style: StrokeStyle(
                        lineWidth: geometry.headHalfWidth * 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(width: size.width, height: size.height)
    }
}
