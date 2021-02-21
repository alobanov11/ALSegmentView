//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

public protocol IALCollaborativeScroll: UIScrollView {
}

open class ALCollaborativeScrollView: UIScrollView, UIGestureRecognizerDelegate, IALCollaborativeScroll
{
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
