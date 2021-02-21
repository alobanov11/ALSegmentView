//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

final class ALSegmentHeaderView: UIView
{
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view?.isKind(of: UIControl.self) ?? false ? view : nil
    }
}
