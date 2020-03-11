//
//  LoggedInBuilder.swift
//  Insite
//
//  Created by Varun Iyer on 2/27/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs

protocol LoggedInDependency: Dependency {
    // TODO: Declare the set of dependencies required by this RIB, but cannot be
    // created by this RIB.
    var loggedInViewController: LoggedInViewControllable { get }
}

final class LoggedInComponent: Component<LoggedInDependency>, MenuDependency {

    // TODO: Declare 'fileprivate' dependencies that are only used by this RIB.
    fileprivate var loggedInViewController: LoggedInViewControllable {
        return dependency.loggedInViewController
    }
    
    let w: CGFloat
    let h: CGFloat
    
    init(dependency: LoggedInDependency, w: CGFloat, h: CGFloat) {
        self.w = w
        self.h = h
        super.init(dependency: dependency)
    }
    
    var mutableMenuStateStream: MutableMenuStateStream {
        return shared { MenuStateStreamImpl() }
    }
    
    var mutablePlacesStream: MutablePlacesStream {
        return shared { PlacesStreamImpl() }
    }
}

// MARK: - Builder

protocol LoggedInBuildable: Buildable {
    func build(withListener listener: LoggedInListener, w: CGFloat, h: CGFloat) -> LoggedInRouting
}

final class LoggedInBuilder: Builder<LoggedInDependency>, LoggedInBuildable {

    override init(dependency: LoggedInDependency) {
        super.init(dependency: dependency)
    }
    
    func build(withListener listener: LoggedInListener, w: CGFloat, h: CGFloat) -> LoggedInRouting {
        let component = LoggedInComponent(dependency: dependency, w: w, h: h)
        let viewController = LoggedInViewController(w: w, h: h)
        let interactor = LoggedInInteractor(presenter: viewController, placesStream: component.mutablePlacesStream, menuStateStream: component.mutableMenuStateStream)
        interactor.listener = listener
        
        let menuBuilder = MenuBuilder(dependency: component)
        return LoggedInRouter(interactor: interactor, viewController: viewController, menuBuilder: menuBuilder)
    }
}
