//
//  OnboardingView.swift
//  BDE-ESEO
//
//  Created by Romain Rabouan on 16/09/2019.
//  Copyright © 2019 Romain Rabouan

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
//

import SwiftUI

@available(iOS 13.0, *)
struct OnboardingView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    
    var body: some View {
        VStack(spacing: 50) {
            
            Spacer()
            
            Text("Bienvenue !")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Voici la fonctionnalité Documents, une des promesses de campagne de ton BDE ESEOKAMI. Elle te permet de consulter les annales d'examens des années passées, pour tes révisions. Plein d'autres fonctionnalités arriveront tout au long de l'année")
                .lineLimit(nil)
                .multilineTextAlignment(.center)
            
            Image(systemName: "doc.text.fill")
                .resizable()
                .foregroundColor(Color.yellow)
                .frame(width: 50, height: 65)
            
            Spacer()
//            
//            Button(action: {
//                self.presentationMode.wrappedValue.dismiss()
//            }) {
//                Text("C'est parti !")
//                    .frame(width: 150, height: 50)
//                    .foregroundColor(Color.white)
//                    .background(Color.blue)
//                    .cornerRadius(15)
//            }
            
        }.padding()
    }
}
