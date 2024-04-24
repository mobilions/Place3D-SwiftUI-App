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

struct ContentView: View {
    @State var screenSize: CGSize = .zero
    var modelsData = ["Chair", "Books", "Clock", "Banans", "Tins", "Bottle", "Robot"]
    var placeModelAction: [Actions] = [.placeChairModel, .placeBooksModel, .placeClockModel, .placeBananesModel, .placeTinsModel, .placeBottleModel, .placeRobotModel]
    @StateObject var viewModel = SharedViewModel()
    @State var selectedAction: Actions = .placeChairModel
    @State private var useHorizontalDetection = true
    @State var validPlaneDetection = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            CustomARViewContainer(viewModel: viewModel)
            
            // MARK: - Get Screen Size
            GeometryReader { GData in
                HStack() {}
                    .onAppear(perform: {
                        screenSize = GData.size
                    })
            }
            
            // MARK: - Main view
            VStack(alignment: .center, spacing: 0) {
                
                // MARK: - Btn Place Object
                VStack() {
                    Spacer()
                        .frame(height: 10)
                    
                    Button("Place object") {
                        ActionManager.shared.actionStream.send(selectedAction)
                    }
                    .font(Font.system(size: 20))
                    .frame(width: abs(screenSize.width - 40), height: 40)
                    .foregroundColor(.white)
                    .background(Color.blue.opacity(0.9))
                    .cornerRadius(10)
                    .onTapGesture {
                        ActionManager.shared.actionStream.send(selectedAction)
                    }
                    Spacer()
                        .frame(height: 5)
                }
                .frame(width: abs(screenSize.width), height: 55)
                
                
                // MARK: - Scroll view
                ScrollView(.horizontal, showsIndicators: false, content: {
                    HStack() {
                        ForEach(0..<modelsData.count, id: \.self) { i in
                            // MARK: - Object Btn's
                            
                            Button(action: {
                                self.selectedAction = self.placeModelAction[i]
                                if self.selectedAction == .placeClockModel {
                                    validPlaneDetection = true
                                    ActionManager.shared.actionStream.send(.VerticalPlane)
                                } else {
                                    if validPlaneDetection {
                                        ActionManager.shared.actionStream.send(.horizontalPlane)
                                    }
                                    validPlaneDetection = false
                                }
                            }) {
                                Text(modelsData[i])
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(self.selectedAction == placeModelAction[i] ? Color.red.opacity(0.9) : Color.blue.opacity(0.9))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.all, 10)
                })
                .padding(.vertical, 5)
                .frame(width: abs(screenSize.width), height: 70)
            }
            .frame(width: abs(screenSize.width), height: 125)
            .background(.white)
            
            // MARK: - Restart Btn
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
            
            // MARK: - Undo Btn
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
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text("Alert"),
                message: Text(viewModel.alertMessage),
                primaryButton: .destructive(Text("OK")) {
                    viewModel.onOK()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct CustomARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: SharedViewModel
    
    func makeUIView(context: Context) -> CustomARView {
        let arView = CustomARView(viewModel: viewModel, frame: .zero)
        return arView
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) {
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
    case horizontalPlane
    case VerticalPlane
    case placeClockModel
}

// MARK: - Action Manager Singleton
class ActionManager {
    static let shared = ActionManager()
    var actionStream = PassthroughSubject<Actions, Never>()
}

// MARK: - Display alert
class SharedViewModel: ObservableObject {
    @Published var showingAlert = false
    @Published var alertMessage = "Refresh the session, click ok to continue"
    
    var onOK: () -> Void = {}
    
    func triggerAlert(message: String, onOKAction: @escaping () -> Void = {}) {
        self.alertMessage = message
        self.onOK = onOKAction
        self.showingAlert = true
    }
}
