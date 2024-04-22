//
//  ContentView.swift
//  AR_DEMO_SWIFTUI
//
//  Created by Mobilions iOS on 22/02/24.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity
import Combine
import SceneKit
import UIKit

var defaultModel = Actions.placeBananesModel

struct ContentView: View {
    @State var screenSize: CGSize = .zero
    var modelsData = ["Chair", "Books", "Banans", "Tins", "Bottle", "Robot"]
    var placeModelAction: [Actions] = [.placeChairModel, .placeBooksModel, .placeBananesModel, .placeTinsModel, .placeBottleModel, .placeRobotModel]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CustomARViewContainer()
            GeometryReader { GData in
                HStack() {}
                    .onAppear(perform: {
                        screenSize = GData.size
                    })
            }
            
            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack() {
                    ForEach(0..<modelsData.count, id: \.self) { i in
                        Button(action: {
                            defaultModel = .placeChairModel
                            ActionManager.shared.actionStream.send(placeModelAction[i])
                        }, label: {
                            Text(modelsData[i])
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue.opacity(0.9))
                                .cornerRadius(10)
                        })
                    }
                    
                }
                .padding(.all, 10)
            })
            .frame(width: abs(screenSize.width), height: 80)
            .background(.white)
            .padding(.all, 0)
            
            Button(action: {
                ActionManager.shared.actionStream.send(.remove3DModel)
            }, label: {
                Text("Restart")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue.opacity(0.5))
                    .cornerRadius(10)
            })
            .frame(height: 20)
            .padding(.bottom, screenSize.height - 44)
            .padding(.trailing, screenSize.width - 100)
            
            
            Button(action: {
                ActionManager.shared.actionStream.send(.removeLast)
            }, label: {
                Text("undo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue.opacity(0.5))
                    .cornerRadius(10)
            })
            .frame(height: 20)
            .padding(.bottom, screenSize.height - 44)
            .padding(.leading, screenSize.width - 80)
            
        }
    }
}

struct CustomARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> CustomARView {
        return CustomARView()
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) {}
}

// MARK: - Custom AR View Handling ARKit
class CustomARView: ARView {
    var focusEntity: FocusEntity?
    var cancellables: Set<AnyCancellable> = []
    var anchorEntities: [AnchorEntity] = []
    let config = ARWorldTrackingConfiguration()
    @State var imageOBJ = Image(named: "Product-2")
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

    init() {
        super.init(frame: .zero)
        configureARSession()
        subscribeToActionStream()
    }

    // MARK: - AR Session Configuration
    private func configureARSession() {
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        self.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // Initialize FocusEntity here
        if self.focusEntity == nil {
            self.focusEntity = FocusEntity(on: self, style: .classic(color: .blue.withAlphaComponent(0.5)))
        }
        self.focusEntity?.isEnabled = true // Make sure it's enabled
        debugPrint("FocusEntity initialized and enabled.")
    }


    // MARK: - Handling Model Placement and Removal Using Actions Enum
    private func handleAction(_ action: Actions) {
        switch action {
        case .placeBananesModel, .placeChairModel, .placeRobotModel, .placeTinsModel, .placeBooksModel, .placeBottleModel:
            place3DModel(type: action)
        case .remove3DModel:
            removeAllModels()
        case .removeLast:
            removeLastModel()
        }
    }
    
    // MARK: - Place 3D Model
    func place3DModel(type: Actions) {
        guard let focusEntity = self.focusEntity else { return }
        let modelName = getModelName(for: type)
        let modelEntity = try! ModelEntity.load(named: modelName)
        let anchorEntity = AnchorEntity(world: focusEntity.position)
        anchorEntity.addChild(modelEntity)
        self.scene.addAnchor(anchorEntity)
        anchorEntities.append(anchorEntity)
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
        default:
            return "pancakes.usdz"
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

// MARK: - Actions Enum
enum Actions {
    case placeBananesModel
    case placeChairModel
    case placeRobotModel
    case placeTinsModel
    case placeBooksModel
    case placeBottleModel
    case remove3DModel
    case removeLast
}

// MARK: - Action Manager Singleton
class ActionManager {
    static let shared = ActionManager()
    var actionStream = PassthroughSubject<Actions, Never>()
}

//
//// MARK: - ARVIEW
//class CustomARView: ARView {
//    
//    var focusEntity: FocusEntity?
//    var cancellables: Set<AnyCancellable> = []
//    var anchorEntityData = AnchorEntity()
//    let config = ARWorldTrackingConfiguration()
//    @State var imageOBJ = Image(named: "Product-2")
//    lazy var mapSaveURL: URL? = {
//        do {
//            return try FileManager.default
//                .url(for: .documentDirectory,
//                     in: .userDomainMask,
//                     appropriateFor: nil,
//                     create: true)
//                .appendingPathComponent("map.arexperience")
//        } catch {
//            fatalError("Can't get file save URL: \(error.localizedDescription)")
//        }
//    }()
//    init() {
//        super.init(frame: .zero)
//        
//        // ActionStrean
//        subscribeToActionStream()
//        // FocusEntity
//        self.focusEntity = FocusEntity(on: self, style: .classic(color: .blue.withAlphaComponent(0.5)))
//        //        anchorEntityData.addChild(modelEntity2)
//        // Configuration
//       
//        switch defaultModel {
//        default:
//            config.planeDetection = [.horizontal, .vertical]
//        }
//        debugPrint("Plane Detection ", config.planeDetection)
//        config.environmentTexturing = .automatic
//        
//        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
//            config.sceneReconstruction = .meshWithClassification
//        }
//        
//        self.session.run(config)
//    }
//    
//    // MARK: - Place  model
//    func place3DModel(type: Actions) {
//        guard let focusEntity = self.focusEntity else { return }
//        var modelName = "pancakes.usdz"
//        switch type {
//        case .placeBananesModel:
//            modelName = "Bananas.usdz"
//        case .placeChairModel:
//            modelName = "chair_swan.usdz"
//        case .placeRobotModel:
//            modelName = "robot_walk_idle.usdz"
//        case .placeBottleModel:
//            modelName = "Bottle_Set.usdz"
//        case .placeTinsModel:
//            modelName = "Tins.usdz"
//        case .placeBooksModel:
//            modelName = "Books.usdz"
//        default:
//            debugPrint(modelName)
//        }
//        let modelEntity = try! ModelEntity.load(named: modelName)
//        let anchorEntity = AnchorEntity(world: focusEntity.position)
//        anchorEntityData.position = focusEntity.position
//        anchorEntityData.addChild(modelEntity)
//        anchorEntity.addChild(modelEntity)
//        //        self.scene.addAnchor(anchorEntityData)
//        self.scene.addAnchor(anchorEntity)
//
//    }
//    
//    // Set true if u want to remove last placed object
//    // MARK: - Destory model
//    func destoryModel(removeLast: Bool = false) {
//        let activity = UIActivityIndicatorView(style: .large)
//        activity.startAnimating()
//        activity.color = .white
//        guard let focusEntity = self.focusEntity else { return }
//        focusEntity.destroy()
//        if removeLast {
//            scene.anchors.count > 0 ? (self.scene.anchors.remove(at: scene.anchors.count - 1)) : debugPrint("Anchor data not found")
//        } else {
//            scene.anchors.count > 0 ? (self.scene.anchors.removeAll()) : debugPrint("Anchor data not found")
//        }
//        
//        self.focusEntity = FocusEntity(on: self, style: .classic(color: .blue.withAlphaComponent(0.5)))
//        //        anchorEntityData.addChild(modelEntity2)
//        // Configuration
//        switch defaultModel {
//        default:
//            config.planeDetection = [.horizontal, .vertical]
//        }
//        debugPrint("Plane Detection ", config.planeDetection)
//        config.environmentTexturing = .automatic
//        
//        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
//            config.sceneReconstruction = .meshWithClassification
//        }
//        
//        self.session.run(config)
//        
//    }
//    func subscribeToActionStream() {
//        ActionManager.shared
//            .actionStream
//            .sink { [weak self] action in
//                
//                switch action {
//                    
//                case .placeChairModel:
//                    self?.place3DModel(type: .placeChairModel )
//                case .remove3DModel:
//                    self?.destoryModel()
//                    
//                case .removeLast:
//                    self?.destoryModel(removeLast: true)
//                case .placeBananesModel:
//                    self?.place3DModel(type: .placeBananesModel)
//                case .placeTinsModel:
//                    self?.place3DModel(type: .placeTinsModel)
//                case .placeBooksModel:
//                    self?.place3DModel(type: .placeBooksModel)
//                case .placeBottleModel:
//                    self?.place3DModel(type: .placeBottleModel)
//                case .placeRobotModel:
//                    self?.place3DModel(type: .placeRobotModel)
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    @MainActor required dynamic init?(coder decoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    @MainActor required dynamic init(frame frameRect: CGRect) {
//        fatalError("init(frame:) has not been implemented")
//    }
//}
//
//enum Actions {
//    case placeBananesModel
//    case placeChairModel
//    case placeRobotModel
//    case placeTinsModel
//    case placeBooksModel
//    case placeBottleModel
//    case remove3DModel
//    case removeLast
//}
//
//class ActionManager {
//    static let shared = ActionManager()
//    
//    private init() { }
//    
//    var actionStream = PassthroughSubject<Actions, Never>()
//}

#Preview {
    ContentView()
}
//
//// Extension to convert CVPixelBuffer to CIImage
//extension CVPixelBuffer {
//    func toCIImage() -> CIImage? {
//        CIImage(cvPixelBuffer: self)
//    }
//}
//
//// Extension to convert CIImage to UIImage
//extension CIImage {
//    func toUIImage(context: CIContext = CIContext(options: nil)) -> UIImage? {
//        if let cgImage = context.createCGImage(self, from: self.extent) {
//            return UIImage(cgImage: cgImage)
//        }
//        return nil
//    }
//}
//
//// Extension to convert UIImage to SwiftUI Image
//extension UIImage {
//    func toSwiftUIImage() -> Image {
//        Image(uiImage: self)
//    }
//}
//
//extension ARWorldMap {
//    var snapshotAnchor: SnapshotAnchor? {
//        return anchors.compactMap { $0 as? SnapshotAnchor }.first
//    }
//}
//
//extension CGImagePropertyOrientation {
//    /// Preferred image presentation orientation respecting the native sensor orientation of iOS device camera.
//    init(cameraOrientation: UIDeviceOrientation) {
//        switch cameraOrientation {
//        case .portrait:
//            self = .right
//        case .portraitUpsideDown:
//            self = .left
//        case .landscapeLeft:
//            self = .up
//        case .landscapeRight:
//            self = .down
//        default:
//            self = .right
//        }
//    }
//}
//
//
///// - Tag: SnapshotAnchor
//class SnapshotAnchor: ARAnchor {
//    
//    let imageData: Data
//    
//    convenience init?(capturing view: ARView) {
//        guard let frame = view.session.currentFrame
//            else { return nil }
//        
//        let image = CIImage(cvPixelBuffer: frame.capturedImage)
//        let orientation = CGImagePropertyOrientation(cameraOrientation: UIDevice.current.orientation)
//        
//        let context = CIContext(options: [.useSoftwareRenderer: false])
//        guard let data = context.jpegRepresentation(of: image.oriented(orientation),
//                                                    colorSpace: CGColorSpaceCreateDeviceRGB(),
//                                                    options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7])
//            else { return nil }
//        
//        self.init(imageData: data, transform: frame.camera.transform)
//    }
//    
//    init(imageData: Data, transform: float4x4) {
//        self.imageData = imageData
//        super.init(name: "snapshot", transform: transform)
//    }
//    
//    required init(anchor: ARAnchor) {
//        self.imageData = (anchor as! SnapshotAnchor).imageData
//        super.init(anchor: anchor)
//    }
//    
//    override class var supportsSecureCoding: Bool {
//        return true
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        if let snapshot = aDecoder.decodeObject(forKey: "snapshot") as? Data {
//            self.imageData = snapshot
//        } else {
//            return nil
//        }
//        
//        super.init(coder: aDecoder)
//    }
//    
//    override func encode(with aCoder: NSCoder) {
//        super.encode(with: aCoder)
//        aCoder.encode(imageData, forKey: "snapshot")
//    }
//
//}
