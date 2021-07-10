//
//  NavigationView.swift
//  BicycleSupporter
//
//  Created by 斉藤虎太郎 on 2021/07/10.
//

import SwiftUI

struct NavigationView: View {
    var body: some View {
        NavigationView {
            // NOTE: NavigationLinkはNavigationViewの内側でなければならない
            NavigationLink(destination: MapView()) {
                // NOTE: Labelを指定すると遷移先へのリンクが自動的に生成される
                Text("Move to SubView")
            }
        }
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
