//
//  HomeBuilder.swift
//  Insite
//
//  Created by Varun Iyer on 3/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs

protocol HomeDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
    var w: CGFloat { get }
    var h: CGFloat { get }
    var mutablePlacesStream: MutablePlacesStream { get }
}

final class HomeComponent: Component<HomeDependency> {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
    var w: CGFloat {
        return dependency.w
    }
    
    var h: CGFloat {
        return dependency.h
    }
    
    var placesStream: MutablePlacesStream {
        return dependency.mutablePlacesStream
    }
}

// MARK: - Builder
protocol HomeBuildable: Buildable {
    func build(withListener listener: HomeListener) -> HomeRouting
}

final class HomeBuilder: Builder<HomeDependency>, HomeBuildable {

    override init(dependency: HomeDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: HomeListener) -> HomeRouting {
        let component = HomeComponent(dependency: dependency)
        let viewController = HomeViewController(w: component.w, h: component.h)
        
        let interactor = HomeInteractor(presenter: viewController, placesStream: component.placesStream)
        interactor.listener = listener
        return HomeRouter(interactor: interactor, viewController: viewController)
    }
}
