//
//  Created by Антон Лобанов on 21.02.2021.
//

import UIKit

public protocol IALSegmentContentView: UIView
{
    var onScroll: (() -> Void)? { get set }
    var scrollView: UIScrollView { get }
}
