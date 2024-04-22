//
//  SampleView.swift
//  AR_DEMO_SWIFTUI
//
//  Created by Mobilions iOS on 01/03/24.
//

import SwiftUI

struct SampleView: View {
    @State private var expand = false
    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: expand ? 300 : 200, height: expand ? 300 : 200)
//            .offset(y: expand ? -200 : 0)
            .animation(.easeInOut(duration: 0.5))
            .animation(.bouncy(duration: 0.5))
            .onTapGesture {
                self.expand.toggle()
            }
            .overlay(
                Circle()
                    .fill(Color.teal)
                    .frame(width: expand ? 250 : 150, height: expand ? 250 : 150)
        //            .offset(y: expand ? -200 : 0)
                    .animation(.easeInOut(duration: 0.5))
                    .animation(.bouncy(duration: 0.5))
                    .onTapGesture {
                        self.expand.toggle()
                    }
                
                .overlay(
                    Circle()
                        .fill(Color.red)
                        .frame(width: expand ? 200 : 100, height: expand ? 200 : 100)
            //            .offset(y: expand ? -200 : 0)
                        .animation(.easeInOut(duration: 0.5))
                        .animation(.bouncy(duration: 0.5))
                        .onTapGesture {
                            self.expand.toggle()
                        }
                    
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: expand ? 150 : 100, height: expand ? 150 : 100)
                //            .offset(y: expand ? -200 : 0)
                            .animation(.easeInOut(duration: 0.5))
                            .animation(.bouncy(duration: 0.5))
                            .onTapGesture {
                                self.expand.toggle()
                            }
                        
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: expand ? 100 : 50, height: expand ? 100 : 50)
                    //            .offset(y: expand ? -200 : 0)
                                .animation(.easeInOut(duration: 0.5))
                                .animation(.bouncy(duration: 0.5))
                                .onTapGesture {
                                    self.expand.toggle()
                                }
                        )
                    )
                )
            )
    }
}

#Preview {
    SampleView()
}
