//
//  LoadingScreen.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/26.
//

import Foundation
import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image("loading1")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}
