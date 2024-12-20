//
//  FilterPoliceView.swift
//  AnshinNavi
//
//  Created by YoungJune Kang on 2024/11/22.
//

import Foundation
import SwiftUI

struct FilterPoliceView: View {
    @Binding var selectedPoliceTypes: [PoliceType]
    
    var body: some View {
        List {
            // Reset button section
            Section {
                Button(action: {
                    selectedPoliceTypes.removeAll()
                }) {
                    Text("フィルターをリセット")
                        .font(.system(size: FONT_SIZE.size))
                        .foregroundColor(.blue)
                }
                .disabled(selectedPoliceTypes.isEmpty)
            }
            
            // Police types section
            Section(
                header: Text("施設種別")
                    .font(.system(size: FONT_SIZE.size * 0.875)),
                footer: Group {
                    if !isUserAppJapanese {
                        Text("WHAT_IS_POLICE_FILTER".localized)
                            .font(.system(size: FONT_SIZE.size * 0.875))
                            .padding(.top, 2)
                            .foregroundColor(.secondary)
                    }
                }
            ) {
                ForEach([PoliceType.honbu, .keisatsusho, .koban], id: \.self) { policeType in
                    FilterToggleRowPolice(
                        policeType: policeType,
                        isSelected: selectedPoliceTypes.contains(policeType),
                        onToggle: { isSelected in
                            handlePoliceFilterToggle(policeType: policeType, isSelected: isSelected)
                        }
                    )
                }
            }
        }
    }
    
    private func handlePoliceFilterToggle(policeType: PoliceType, isSelected: Bool) {
        if isSelected {
            if !selectedPoliceTypes.contains(policeType) {
                selectedPoliceTypes.append(policeType)
            }
        } else {
            selectedPoliceTypes.removeAll { $0 == policeType }
        }
    }
}

private struct FilterToggleRowPolice: View {
    let policeType: PoliceType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 12) {
                Image(systemName: policeType.iconName)
                    .font(.system(size: FONT_SIZE.size))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(policeType.localizedName)
                    .font(.system(size: FONT_SIZE.size))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: FONT_SIZE.size))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 24)
            }
        }
    }
}
