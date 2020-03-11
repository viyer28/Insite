//
//  LoggedInRouter.swift
//  Insite
//
//  Created by Varun Iyer on 2/27/20.
//  Copyright © 2020 spott. All rights reserved.
//

import RIBs

protocol LoggedInInteractable: Interactable, MenuListener {
    var router: LoggedInRouting? { get set }
    var listener: LoggedInListener? { get set }
}

protocol LoggedInViewControllable: ViewControllable {
    // TODO: Declare methods the router invokes to manipulate the view hierarchy.
    func show(view: ViewControllable)
    func hide(view: ViewControllable)
}

final class LoggedInRouter: ViewableRouter<LoggedInInteractable, LoggedInViewControllable>, LoggedInRouting {

    // TODO: Constructor inject child builder protocols to allow building children.
    init(interactor: LoggedInInteractable, viewController: LoggedInViewControllable, menuBuilder: MenuBuildable) {
        self.menuBuilder = menuBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    override func didLoad() {
        super.didLoad()
        
        attachMenu()
    }
    
    // MARK: - Menu
    
    private var menuBuilder: MenuBuildable
    
    private func attachMenu() {
        let menu = menuBuilder.build(withListener: interactor)
        attachChild(menu)
        viewController.show(view: menu.viewControllable)
    }
}
