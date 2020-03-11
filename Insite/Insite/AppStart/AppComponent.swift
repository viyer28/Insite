//
//  AppComponent.swift
//  Insite
//
//  Created by Varun Iyer on 2/27/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs

class AppComponent: Component<EmptyDependency>, RootDependency {
    init() {
        super.init(dependency: EmptyComponent())
    }
}
