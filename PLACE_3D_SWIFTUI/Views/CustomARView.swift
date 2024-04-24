//
//  CustomARView.swift
//  PLACE_3D_SWIFTUI
//
//  Created by Mobilions iOS on 22/04/24.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity
import Combine
import SceneKit
import UIKit

// MARK: - Custom AR View Handling ARKit
class CustomARView: ARView {
    var focusEntity: FocusEntity?
    var cancellables: Set<AnyCancellable> = []
    var anchorEntities: [AnchorEntity] = []
    let config = ARWorldTrackingConfiguration()
    @ObservedObject var viewModel: SharedViewModel
    @State var planeConfigration = ARObjectScanningConfiguration().planeDetection
    var isHorizontal = true
    
    lazy var mapSaveURL: URL? = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    init(viewModel: SharedViewModel, frame: CGRect) {
        self.viewModel = viewModel
        super.init(frame: frame)
        configureARSession()
        subscribeToActionStream()
    }
    
    // MARK: - AR Session Configuration
    private func configureARSession() {
        config.planeDetection = [.horizontal]
//        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        self.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // Initialize FocusEntity here
        if self.focusEntity == nil {
            self.focusEntity = FocusEntity(on: self, style: .classic(color: .blue.withAlphaComponent(0.5)))
        }
        self.focusEntity?.isEnabled = true
        self.focusEntity?.delegate = self
        
        debugPrint("FocusEntity initialized and enabled.")
        debugPrint("Plane Detection :: \(config.planeDetection)")
    }
    
    
    // MARK: - Handling Model Placement and Removal Using Actions Enum
    private func handleAction(_ action: Actions) {
        switch action {
        case .placeBananesModel, .placeChairModel, .placeRobotModel, .placeTinsModel, .placeBooksModel, .placeBottleModel, .placeClockModel:
            place3DModel(type: action)
        case .remove3DModel:
            removeAllModels()
        case .removeLast:
            removeLastModel()
        case .VerticalPlane:
            isPlaneHorizontal(false)
        case .horizontalPlane:
            isPlaneHorizontal(true)
        }
    }
    
    func isPlaneHorizontal(_ yes: Bool) {
        session.pause()
        yes ? (config.planeDetection = [.horizontal]) : (config.planeDetection = [.vertical])
        
        session.run(config, options: [.removeExistingAnchors])
        if yes {
            isHorizontal = true
            debugPrint("Its Horizontal :: \(isHorizontal)")
        } else {
            isHorizontal = false
            debugPrint("Its Horizontal :: \(isHorizontal)")
        }
    }
    
    // MARK: - Place 3D Model
    func place3DModel(type: Actions) {
        
        guard let focusEntity = self.focusEntity else { return }
//        if (focusEntity.isHorizontal == true) && (isHorizontal == true) {
//            debugPrint("Horizontal")
//        } else if (focusEntity.isHorizontal == false) && (isHorizontal == false) {
//            debugPrint("Vertical")
//        } else {
//            return
//        }
        if ((focusEntity.currentPlaneAnchor?.alignment == .horizontal) && (isHorizontal == true)) || ((focusEntity.currentPlaneAnchor?.alignment == .vertical) && (isHorizontal == false)) {
            let modelName = getModelName(for: type)
            let modelEntity = try! ModelEntity.load(named: modelName)
            let anchorEntity = AnchorEntity(world: focusEntity.position)
            
            if anchorEntities.count < 7 {
                anchorEntity.addChild(modelEntity)
                self.scene.addAnchor(anchorEntity)
                anchorEntities.append(anchorEntity)
            } else {
                showAlert("Refresh the session, click ok to continue")
            }
        }
    }
    
    // MARK: - Get Model Name from Action
    private func getModelName(for action: Actions) -> String {
        switch action {
        case .placeBananesModel:
            return "Bananas.usdz"
        case .placeChairModel:
            return "chair_swan.usdz"
        case .placeRobotModel:
            return "robot_walk_idle.usdz"
        case .placeBottleModel:
            return "Bottle_Set.usdz"
        case .placeTinsModel:
            return "Tins.usdz"
        case .placeBooksModel:
            return "Books.usdz"
        case .placeClockModel:
            return "Clock.usdz"
        default:
            return ""
        }
    }
    
    // MARK: - Remove Last Model
    func removeLastModel() {
        if let lastAnchor = anchorEntities.popLast() {
            self.scene.removeAnchor(lastAnchor)
        }
    }
    
    // MARK: - Remove All Models
    func removeAllModels() {
        anchorEntities.forEach { anchor in
            self.scene.removeAnchor(anchor)
        }
        anchorEntities.removeAll()
    }
    
    func showAlert(_ message: String) {
        DispatchQueue.main.async {
            self.viewModel.triggerAlert(message: message, onOKAction: self.removeAllModels)
        }
    }
    
    
    // MARK: - Subscribe to Action Stream
    private func subscribeToActionStream() {
        ActionManager.shared.actionStream.receive(on: DispatchQueue.main).sink { action in
            self.handleAction(action)
        }.store(in: &cancellables)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
}

extension Entity {
    var isHorizontal: Bool {
        (self as? ARPlaneAnchor)?.alignment == .horizontal
    }
}

extension CustomARView: FocusEntityDelegate {
    
//    func focusEntity(_ focusEntity: FocusEntity, planeChanged: ARPlaneAnchor?, oldPlane: ARPlaneAnchor?) {
//        if planeChanged?.alignment == .horizontal {
//            debugPrint("It's Horizontal")
//        } else if planeChanged?.alignment == .vertical {
//            debugPrint("It's Vertical")
//        } else {
//            debugPrint("Not found")
//        }
//    }
}

#Preview {
    CustomARView(frame: .zero)
}
