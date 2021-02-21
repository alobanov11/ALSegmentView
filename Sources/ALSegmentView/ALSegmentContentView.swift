//
//  Created by Антон Лобанов on 21.02.2021.
//

import UIKit

public protocol IALSegmentContentView: UIView
{
    var onSegmentScroll: (() -> Void)? { get set }
    var segmentScrollView: IALCollaborativeScroll { get }
}
