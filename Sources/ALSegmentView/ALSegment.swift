//
//  Created by Антон Лобанов on 20.02.2021.
//

import UIKit

public final class ALSegment
{
    let title: String
    let contentBuilder: () -> IALSegmentContentView
    lazy var content: IALSegmentContentView = self.contentBuilder()
    
    public init(
        _ title: String,
        _ contentBuilder: @escaping () -> IALSegmentContentView
    ) {
        self.title = title
        self.contentBuilder = contentBuilder
    }
}
