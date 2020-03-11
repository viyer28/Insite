//
//  NavigationBuilder.swift
//  Insite
//
//  Created by Varun Iyer on 3/11/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs

protocol NavigationDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
    var w: CGFloat { get }
    var h: CGFloat { get }
    var mutableMenuStateStream: MutableMenuStateStream { get }
    var mutablePlacesStream: MutablePlacesStream { get }
}

final class NavigationComponent: Component<NavigationDependency> {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
    var w: CGFloat {
       return dependency.w
    }

    var h: CGFloat {
       return dependency.h
    }
    
    var mutableMenuStateStream: MutableMenuStateStream {
       return dependency.mutableMenuStateStream
    }
    
    var mutablePlacesStream: MutablePlacesStream {
        return dependency.mutablePlacesStream
    }
}

// MARK: - Builder

protocol NavigationBuildable: Buildable {
    func build(withListener listener: NavigationListener) -> NavigationRouting
}

final class NavigationBuilder: Builder<NavigationDependency>, NavigationBuildable {

    override init(dependency: NavigationDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: NavigationListener) -> NavigationRouting {
        let component = NavigationComponent(dependency: dependency)
        let viewController = NavigationViewController(w: component.w, h: component.h)
        
        let interactor = NavigationInteractor(presenter: viewController, placesStream: component.mutablePlacesStream, menuStateStream: component.mutableMenuStateStream)
        interactor.listener = listener
        return NavigationRouter(interactor: interactor, viewController: viewController)
    }
}
