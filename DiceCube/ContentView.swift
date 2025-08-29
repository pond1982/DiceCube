//
//  ContentView.swift
//  DiceCube
//
//  Created by Pondd Air on 29/8/2568 BE.
//

import SwiftUI
import SceneKit
import UIKit

class DiceNode: SCNNode {
    init(faceImages: [UIImage], size: CGFloat = 0.5) {
        super.init()
        let cube = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        cube.materials = faceImages.map { image in
            let material = SCNMaterial()
            material.diffuse.contents = image
            material.locksAmbientWithDiffuse = true
            material.lightingModel = .constant
            return material
        }
        self.geometry = cube
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ContentView: View {
    @State private var scene: SCNScene?

    private func diceFaceImage(for number: Int) -> UIImage {
        // Create image size and dot parameters
        let size = CGSize(width: 256, height: 256)
        let dotRadius: CGFloat = 24
        let dotColor = UIColor.black

        // Positions for pips relative to image size
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let offset = size.width / 4

        let left = center.x - offset
        let right = center.x + offset
        let top = CGPoint(x: center.x, y: center.y - offset)
        let bottom = CGPoint(x: center.x, y: center.y + offset)

        // Helper function to draw a single dot at given position
        func drawDot(at point: CGPoint, in context: CGContext) {
            context.addEllipse(in: CGRect(x: point.x - dotRadius, y: point.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
            context.setFillColor(dotColor.cgColor)
            context.fillPath()
        }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return UIImage()
        }

        // White background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Draw pips based on dice number
        switch number {
        case 1:
            drawDot(at: center, in: context)
        case 2:
            drawDot(at: top, in: context)
            drawDot(at: bottom, in: context)
        case 3:
            drawDot(at: center, in: context)
            drawDot(at: top, in: context)
            drawDot(at: bottom, in: context)
        case 4:
            drawDot(at: CGPoint(x: left, y: top.y), in: context)
            drawDot(at: CGPoint(x: right, y: top.y), in: context)
            drawDot(at: CGPoint(x: left, y: bottom.y), in: context)
            drawDot(at: CGPoint(x: right, y: bottom.y), in: context)
        case 5:
            drawDot(at: center, in: context)
            drawDot(at: CGPoint(x: left, y: top.y), in: context)
            drawDot(at: CGPoint(x: right, y: top.y), in: context)
            drawDot(at: CGPoint(x: left, y: bottom.y), in: context)
            drawDot(at: CGPoint(x: right, y: bottom.y), in: context)
        case 6:
            drawDot(at: CGPoint(x: left, y: top.y), in: context)
            drawDot(at: CGPoint(x: right, y: top.y), in: context)
            drawDot(at: CGPoint(x: left, y: center.y), in: context)
            drawDot(at: CGPoint(x: right, y: center.y), in: context)
            drawDot(at: CGPoint(x: left, y: bottom.y), in: context)
            drawDot(at: CGPoint(x: right, y: bottom.y), in: context)
        default:
            break
        }

        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }

    func makeCubeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.gray

        // Assign dice face images to cube faces
        // Face order for SCNBox materials:
        // 0: +Z (front)
        // 1: -Z (back)
        // 2: +Y (top)
        // 3: -Y (bottom)
        // 4: -X (left)
        // 5: +X (right)
        let faceImages = [
            diceFaceImage(for: 1), // +Z (front)
            diceFaceImage(for: 6), // -Z (back)
            diceFaceImage(for: 3), // +Y (top)
            diceFaceImage(for: 4), // -Y (bottom)
            diceFaceImage(for: 5), // -X (left)
            diceFaceImage(for: 2)  // +X (right)
        ]

        let dice1 = DiceNode(faceImages: faceImages)
        dice1.position = SCNVector3(-0.6, 0, 0)
        scene.rootNode.addChildNode(dice1)

        let dice2 = DiceNode(faceImages: faceImages)
        dice2.position = SCNVector3(0.6, 0, 0)
        scene.rootNode.addChildNode(dice2)

        // Add a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 6)
        scene.rootNode.addChildNode(cameraNode)

        // Add a light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 2, 2)
        scene.rootNode.addChildNode(lightNode)

        // Add ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLightNode)

        return scene
    }

    var body: some View {
        SceneView(
            scene: scene,
            options: [.autoenablesDefaultLighting, .allowsCameraControl]
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RepresentedGestureView(scene: $scene))
        .onAppear {
            scene = makeCubeScene()
        }
    }
}

struct RepresentedGestureView: UIViewRepresentable {
    @Binding var scene: SCNScene?
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(scene: $scene)
    }
    class Coordinator: NSObject {
        var scene: Binding<SCNScene?>
        init(scene: Binding<SCNScene?>) { self.scene = scene }
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let uiView = sender.view,
                  let scene = scene.wrappedValue,
                  let window = uiView.window else { return }
            let scnViews = window.subviews.compactMap { $0 as? SCNView }
            guard let scnView = scnViews.first else { return }
            let location = sender.location(in: scnView)
            let results = scnView.hitTest(location, options: nil)
            if let diceNode = results.first(where: { $0.node is DiceNode })?.node as? DiceNode {
                // Example interaction: rotate the tapped dice
                let spin = CABasicAnimation(keyPath: "rotation")
                spin.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
                spin.duration = 0.5
                spin.repeatCount = 1
                diceNode.addAnimation(spin, forKey: "spin-tap")
            }
        }
    }
}

#Preview {
    ContentView()
}

