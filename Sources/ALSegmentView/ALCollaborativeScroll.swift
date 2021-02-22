//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

public protocol IALCollaborativeScroll: UIScrollView {
}

open class ALCollaborativeScrollView: UIScrollView, UIGestureRecognizerDelegate, IALCollaborativeScroll
{
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view?.isKind(of: UIControl.self) ?? false ? view : nil
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is IALCollaborativeScroll
    }
    
    public override func touchesShouldCancel(in view: UIView) -> Bool {
        view.isKind(of: UIControl.self) ? true : super.touchesShouldCancel(in: view)
    }
}

open class ALCollaborativeCollectionView: UICollectionView, UIGestureRecognizerDelegate, IALCollaborativeScroll
{
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view?.isKind(of: UIControl.self) ?? false ? view : nil
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is IALCollaborativeScroll
    }
    
    public override func touchesShouldCancel(in view: UIView) -> Bool {
        view.isKind(of: UIControl.self) ? true : super.touchesShouldCancel(in: view)
    }
}

open class ALCollaborativeTableView: UITableView, UIGestureRecognizerDelegate, IALCollaborativeScroll
{
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view?.isKind(of: UIControl.self) ?? false ? view : nil
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer.view is IALCollaborativeScroll
    }
    
    public override func touchesShouldCancel(in view: UIView) -> Bool {
        view.isKind(of: UIControl.self) ? true : super.touchesShouldCancel(in: view)
    }
}
